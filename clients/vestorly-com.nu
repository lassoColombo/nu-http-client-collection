# Auto-generated client for Vestorly API v1.0.0
# Source: https://api.apis.guru/v2/specs/vestorly.com/1.0.0/swagger.json
# Auth: --token flag or $env.VESTORLY_API_TOKEN

const BASE_URL = "https://staging.vestorly.com/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VESTORLY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://staging.vestorly.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["bounce" "click" "content_posted" "create_post" "delete_post" "delivered" "dropped" "invite" "open" "page_view" "publish_newsletter" "publish_post" "publish_social" "sign_in" "sign_up" "unpublish_post" "update_post"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "advisors find" } } | get name | first)
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

# Returns a single advisor given their ID
#
# GET /advisors/{id}
# operationId: findAdvisorByID
export def "advisors find" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<about: string, account_type: string, address: string, adv_brochure: string, api_key: string, city: string, company: string, compliance_bcc_email_address: string, dashboard_url: string, disclosure: string, email_report_blast: string, external_options: string, first_name: string, id: string, last_name: string, linkedin: string, logo: string, name: string, plan: string, profile_picture: string, reg_number: string, state: string, tag: string, twitter_handle: string, website: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/advisors/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns phrases used in Categories
#
# GET /article_phrases
# operationId: findArticlePhrases
export def "article-phrases find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --text-search: string # Text to search phrases
  --size: int # Number of returned phrases
  --qp-from: int # Number of phrases to skip
]: nothing -> record<article_phrases: table<created_at: int, length: int, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "text_search" $text_search "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/article_phrases" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token, "text_search": $text_search, "size": $size, "from": $qp_from} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all articles
#
# GET /articles
# operationId: findArticles
export def "articles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --limit: int # Limit on the number of articles to return (format: int32)
  --text-query: string # Search query parameter
  --sort-direction: string # Direction of sort (used with sort_by parameter)
  --sort-by: string # Field on model to sort by
]: nothing -> record<articles: table<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "text_query" $text_query "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_by" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token, "limit": $limit, "text_query": $text_query, "sort_direction": $sort_direction, "sort_by": $sort_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a single article
#
# GET /articles/{id}
# operationId: findArticleByID
export def "articles find" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<article: record<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/articles/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all Categorie's filters
#
# GET /custom_feed_filters
# operationId: findCustomFeedFilters
export def "custom-feed-filters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<custom_feed_filters: table<_id: string, custom_feed_id: string, source_ids: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_feed_filters" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Category filter
#
# POST /custom_feed_filters
# operationId: createCustomFeedFilter
export def "custom-feed-filters create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  custom_feed_id: string
  --source-ids: list<string>
]: any -> record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_feed_filters" $qp $auth.query)
  let req_body = {"custom_feed_id": $custom_feed_id, "source_ids": $source_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the Category's filter
#
# DELETE /custom_feed_filters/{id}
# operationId: deleteCustomFeedFilter
export def "custom-feed-filters delete" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feed_filters/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns a single Category's filter
#
# GET /custom_feed_filters/{id}
# operationId: findCustomFeedFilterByID
export def "custom-feed-filters find" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feed_filters/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a Category Feed Filter
#
# PUT /custom_feed_filters/{id}
# operationId: updateCustomFeedFilterById
export def "custom-feed-filters update" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  custom_feed_id: string
  --source-ids: list<string>
]: any -> record<custom_feed_filter: record<_id: string, custom_feed_id: string, source_ids: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feed_filters/{id}") $qp $auth.query)
  let req_body = {"custom_feed_id": $custom_feed_id, "source_ids": $source_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all Categories
#
# GET /custom_feeds
# operationId: findCustomFeeds
export def "custom-feeds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<custom_feeds: table<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_feeds" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Category
#
# POST /custom_feeds
# operationId: createCustomFeed
export def "custom-feeds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --custom-feed-filter-id: string
  --custom-feed-permission-id: string
  --custom-feed-visibility: int # format: int32
  --default: oneof<nothing, bool>
  --is-auto-curated-newsletter-custom-feed: oneof<nothing, bool>
  label: string
  --popularity: float # format: float
  --premium-content: oneof<nothing, bool>
  --seed-custom-feed-id: string
  --social-posting-id: string
  --third-party-articles-custom-feed-id: string
]: any -> record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_feeds" $qp $auth.query)
  let req_body = {"custom_feed_filter_id": $custom_feed_filter_id, "custom_feed_permission_id": $custom_feed_permission_id, "custom_feed_visibility": $custom_feed_visibility, "default": $default, "is_auto_curated_newsletter_custom_feed": $is_auto_curated_newsletter_custom_feed, "label": $label, "popularity": $popularity, "premium_content": $premium_content, "seed_custom_feed_id": $seed_custom_feed_id, "social_posting_id": $social_posting_id, "third_party_articles_custom_feed_id": $third_party_articles_custom_feed_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a new Category
#
# DELETE /custom_feeds/{id}
# operationId: deleteCustomFeed
export def "custom-feeds delete" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feeds/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns a single Category
#
# GET /custom_feeds/{id}
# operationId: findCustomFeedByID
export def "custom-feeds find" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feeds/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a Category
#
# PUT /custom_feeds/{id}
# operationId: updateCategoryById
export def "custom-feeds update-category" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --custom-feed-filter-id: string
  --custom-feed-permission-id: string
  --custom-feed-visibility: int # format: int32
  --default: oneof<nothing, bool>
  --is-auto-curated-newsletter-custom-feed: oneof<nothing, bool>
  label: string
  --popularity: float # format: float
  --premium-content: oneof<nothing, bool>
  --seed-custom-feed-id: string
  --social-posting-id: string
  --third-party-articles-custom-feed-id: string
]: any -> record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feeds/{id}") $qp $auth.query)
  let req_body = {"custom_feed_filter_id": $custom_feed_filter_id, "custom_feed_permission_id": $custom_feed_permission_id, "custom_feed_visibility": $custom_feed_visibility, "default": $default, "is_auto_curated_newsletter_custom_feed": $is_auto_curated_newsletter_custom_feed, "label": $label, "popularity": $popularity, "premium_content": $premium_content, "seed_custom_feed_id": $seed_custom_feed_id, "social_posting_id": $social_posting_id, "third_party_articles_custom_feed_id": $third_party_articles_custom_feed_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns Articles by Category
#
# GET /custom_feeds/{id}/articles
# operationId: findCustomFeedArticles
export def "custom-feeds-articles find" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --limit: int # Limit on the number of articles to return (format: int32)
  --sort-by: string # Field on model to sort by
  --start: int # Field where the fetch will start from (format: int32)
  --created-at-gte-days-ago: string # Filter retrieved articles since this date
  --text-query: string # Search query parameter
]: nothing -> record<articles: table<_id: string, body: string, created_at: string, external_url: string, external_url_source: string, external_url_type: string, image_height: int, image_path: string, image_url: string, image_width: int, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_responsive: bool, logo_url: string, needs_sanitize: bool, proxy_url: string, redirector_link: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "created_at_gte_days_ago" $created_at_gte_days_ago "scalar") (serialize-qp "text_query" $text_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feeds/{id}/articles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token, "limit": $limit, "sort_by": $sort_by, "start": $start, "created_at_gte_days_ago": $created_at_gte_days_ago, "text_query": $text_query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Duplicates Category
#
# POST /custom_feeds/{id}/duplicates
# operationId: duplicateCustomFeed
export def "custom-feeds-duplicates create" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<custom_feed: record<_id: string, custom_feed_filter_id: string, custom_feed_permission_id: string, custom_feed_template_id: string, custom_feed_visibility: int, default: bool, display_label: string, is_auto_curated_newsletter_custom_feed: bool, label: string, links: string, popularity: float, premium_content: bool, seed_custom_feed_id: string, third_party_articles_custom_feed_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_feeds/{id}/duplicates") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns all events
#
# GET /events
# operationId: findEvents
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<events: table<_id: string, advisor_id: string, created_at: string, event_content: record, original_url: string, originator_email: string, originator_id: string, parent_event_id: string, referer: string, subject_email: string, subject_id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new event in the system
#
# POST /events
# operationId: createEvent
# --event_content shape: {_id?: string, content_field?: string, content_id?: string, content_type?: string, created_at?: string, slug?: string, updated_at?: string}
export def "events create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --advisor-id: string
  --created-at: string
  --event-content: any # shape: {_id?: string, content_field?: string, content_id?: string, content_type?: string, created_at?: string, slug?: string, updated_at?: string}
  original_url: string
  --originator-email: string
  --originator-id: string
  --parent-event-id: string
  --referer: string
  subject_email: string
  --subject-id: string
  type: string@type-completer
]: any -> record<meta: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp $auth.query)
  let req_body = {"advisor_id": $advisor_id, "created_at": $created_at, "event_content": $event_content, "original_url": $original_url, "originator_email": $originator_email, "originator_id": $originator_id, "parent_event_id": $parent_event_id, "referer": $referer, "subject_email": $subject_email, "subject_id": $subject_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a single event if the user has access
#
# GET /events/{id}
# operationId: findEventByID
export def "events find" [
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
  --access-token: string # OAuth Token
  --vestorly-auth: string # Vestorly Auth Token
]: nothing -> record<event: record<_id: string, advisor_id: string, created_at: string, event_content: record<_id: string, content_field: string, content_id: string, content_type: string, created_at: string, slug: string, updated_at: string>, original_url: string, originator_email: string, originator_id: string, parent_event_id: string, referer: string, subject_email: string, subject_id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "access_token" $access_token "scalar") (serialize-qp "vestorly_auth" $vestorly_auth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"access_token": $access_token, "vestorly_auth": $vestorly_auth} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all groups
#
# GET /groups
# operationId: findGroups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (format: string)
  --access-token: string # OAuth Token
]: nothing -> record<groups: table<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Group
#
# POST /groups
# operationId: createGroup
export def "groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (format: string)
  --access-token: string # OAuth Token
  id: string
  --autopublish: oneof<nothing, bool>
  --is-default: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --name: string
  --new-weekly-mailer-content: string
  --newsletter-subject: string
  --number-articles-per-group: int # format: int32
  --number-articles-per-newsletter: int # format: int32
]: any -> record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp $auth.query)
  let req_body = {"_id": $id, "autopublish": $autopublish, "is_default": $is_default, "is_hidden": $is_hidden, "name": $name, "new_weekly_mailer_content": $new_weekly_mailer_content, "newsletter_subject": $newsletter_subject, "number_articles_per_group": $number_articles_per_group, "number_articles_per_newsletter": $number_articles_per_newsletter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a Group
#
# DELETE /groups/{id}
# operationId: deleteGroup
export def "groups delete" [
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
  --vestorly-auth: string # Vestorly Auth Token (format: string)
  --access-token: string # OAuth Token
]: nothing -> record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns a single group if user has access
#
# GET /groups/{id}
# operationId: findGroupByID
export def "groups find" [
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
  --vestorly-auth: string # Vestorly Auth Token (format: string)
  --access-token: string # OAuth Token
]: nothing -> record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a Group
#
# PUT /groups/{id}
# operationId: updateGroupById
export def "groups update" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --body-id: string
  --autopublish: oneof<nothing, bool>
  --is-default: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --name: string
  --new-weekly-mailer-content: string
  --newsletter-subject: string
  --number-articles-per-group: int # format: int32
  --number-articles-per-newsletter: int # format: int32
]: any -> record<group: record<_id: string, autopublish: bool, is_default: bool, is_hidden: bool, name: string, new_weekly_mailer_content: string, newsletter_subject: string, number_articles_per_group: int, number_articles_per_newsletter: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}") $qp $auth.query)
  let req_body = {"_id": $body_id, "autopublish": $autopublish, "is_default": $is_default, "is_hidden": $is_hidden, "name": $name, "new_weekly_mailer_content": $new_weekly_mailer_content, "newsletter_subject": $newsletter_subject, "number_articles_per_group": $number_articles_per_group, "number_articles_per_newsletter": $number_articles_per_newsletter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all MemberEvents
#
# GET /member_events
# operationId: findMemberEvents
export def "member-events find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<member_events: table<_id: string, content_url: string, created_at: string, event_date: string, event_source: string, event_type: string, member_id: string, original_url: string, originator_email: string, originator_group_id: string, originator_id: string, originator_name: string, originator_type: string, parent_event_id: string, parent_originator_id: string, referer: string, source: string, subject_id: string, type: string, username: string>, members: table<_id: string, added_on: string, email: string, first_name: string, last_name: string, picture_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/member_events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all member reports
#
# GET /member_reports
# operationId: findMemberReports
export def "member-reports find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<member_reports: table<day: int, event_count: int, originator_group_id: string, parent_originator_id: string, source: string, type: string, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/member_reports" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all members
#
# GET /members
# operationId: findMembers
export def "members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token (format: string)
  --access-token: string # OAuth Token
  --start: int # Skips number of members from start
  --limit: int # Number of members to return
]: nothing -> record<members: table<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list, tags: list, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>, meta: record<message: string>, more_results: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/members" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token, "start": $start, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new member in the Vestorly Platform
#
# POST /members
# operationId: createMember
export def "members create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  id: string
  --address: string
  --age: string
  --assets: string
  --city: string
  --data-estimated: oneof<nothing, bool>
  --education: string
  email: string
  --estimated-location: string
  --estimated-zip: string
  --family: string
  --first-name: string
  --gender: string
  --genuine-email: oneof<nothing, bool>
  --high-net-worth: oneof<nothing, bool>
  --home-market-value: string
  --home-owner-status: string
  --hometown: string
  --household-income: string
  --interest-consultation: string
  --interest-in-new-advisor: string
  --invited-by: string
  --invited-on: string
  --is-client: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --last-active-date: string
  --last-name: string
  --location: string
  --marital-status: string
  --message: string
  --occupation: string
  --phone: string
  --picture-url: string
  --portfolio-size: string
  --profile-url: string
  --register-ip-addr: string
  --signed-up-with: string
  --state: string
  --subscribed-group-ids: list<string>
  --tags: list<string>
  --unsubscribed: oneof<nothing, bool>
  --unsubscribed-date: oneof<nothing, bool>
  --user-type: string
  --zip: string
]: any -> record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/members" $qp $auth.query)
  let req_body = {"_id": $id, "address": $address, "age": $age, "assets": $assets, "city": $city, "data_estimated": $data_estimated, "education": $education, "email": $email, "estimated_location": $estimated_location, "estimated_zip": $estimated_zip, "family": $family, "first_name": $first_name, "gender": $gender, "genuine_email": $genuine_email, "high_net_worth": $high_net_worth, "home_market_value": $home_market_value, "home_owner_status": $home_owner_status, "hometown": $hometown, "household_income": $household_income, "interest_consultation": $interest_consultation, "interest_in_new_advisor": $interest_in_new_advisor, "invited_by": $invited_by, "invited_on": $invited_on, "is_client": $is_client, "is_hidden": $is_hidden, "last_active_date": $last_active_date, "last_name": $last_name, "location": $location, "marital_status": $marital_status, "message": $message, "occupation": $occupation, "phone": $phone, "picture_url": $picture_url, "portfolio_size": $portfolio_size, "profile_url": $profile_url, "register_ip_addr": $register_ip_addr, "signed_up_with": $signed_up_with, "state": $state, "subscribed_group_ids": $subscribed_group_ids, "tags": $tags, "unsubscribed": $unsubscribed, "unsubscribed_date": $unsubscribed_date, "user_type": $user_type, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a single member
#
# GET /members/{id}
# operationId: findMemberByID
export def "members find" [
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
  --vestorly-auth: string # Vestorly Auth Token (format: string)
  --access-token: string # OAuth Token
]: nothing -> record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/members/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a single member
#
# PUT /members/{id}
# operationId: updateMemberByID
export def "members update" [
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
  --vestorly-auth: string # Vestorly Auth Token (format: string)
  --access-token: string # OAuth Token
  --body-id: string
  --address: string
  --age: string
  --assets: string
  --city: string
  --data-estimated: oneof<nothing, bool>
  --education: string
  email: string
  --estimated-location: string
  --estimated-zip: string
  --family: string
  --first-name: string
  --gender: string
  --genuine-email: oneof<nothing, bool>
  --high-net-worth: oneof<nothing, bool>
  --home-market-value: string
  --home-owner-status: string
  --hometown: string
  --household-income: string
  --interest-consultation: string
  --interest-in-new-advisor: string
  --invited-by: string
  --invited-on: string
  --is-client: oneof<nothing, bool>
  --is-hidden: oneof<nothing, bool>
  --last-active-date: string
  --last-name: string
  --location: string
  --marital-status: string
  --message: string
  --occupation: string
  --phone: string
  --picture-url: string
  --portfolio-size: string
  --profile-url: string
  --register-ip-addr: string
  --signed-up-with: string
  --state: string
  --subscribed-group-ids: list<string>
  --tags: list<string>
  --unsubscribed: oneof<nothing, bool>
  --unsubscribed-date: oneof<nothing, bool>
  --user-type: string
  --zip: string
]: any -> record<member: record<_id: string, address: string, age: string, assets: string, city: string, data_estimated: bool, education: string, email: string, estimated_location: string, estimated_zip: string, family: string, first_name: string, gender: string, genuine_email: bool, high_net_worth: bool, home_market_value: string, home_owner_status: string, hometown: string, household_income: string, interest_consultation: string, interest_in_new_advisor: string, invited_by: string, invited_on: string, is_client: bool, is_hidden: bool, last_active_date: string, last_name: string, location: string, marital_status: string, message: string, occupation: string, phone: string, picture_url: string, portfolio_size: string, profile_url: string, register_ip_addr: string, signed_up_with: string, state: string, subscribed_group_ids: list<string>, tags: list<string>, unsubscribed: bool, unsubscribed_date: bool, user_type: string, zip: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/members/{id}") $qp $auth.query)
  let req_body = {"_id": $body_id, "address": $address, "age": $age, "assets": $assets, "city": $city, "data_estimated": $data_estimated, "education": $education, "email": $email, "estimated_location": $estimated_location, "estimated_zip": $estimated_zip, "family": $family, "first_name": $first_name, "gender": $gender, "genuine_email": $genuine_email, "high_net_worth": $high_net_worth, "home_market_value": $home_market_value, "home_owner_status": $home_owner_status, "hometown": $hometown, "household_income": $household_income, "interest_consultation": $interest_consultation, "interest_in_new_advisor": $interest_in_new_advisor, "invited_by": $invited_by, "invited_on": $invited_on, "is_client": $is_client, "is_hidden": $is_hidden, "last_active_date": $last_active_date, "last_name": $last_name, "location": $location, "marital_status": $marital_status, "message": $message, "occupation": $occupation, "phone": $phone, "picture_url": $picture_url, "portfolio_size": $portfolio_size, "profile_url": $profile_url, "register_ip_addr": $register_ip_addr, "signed_up_with": $signed_up_with, "state": $state, "subscribed_group_ids": $subscribed_group_ids, "tags": $tags, "unsubscribed": $unsubscribed, "unsubscribed_date": $unsubscribed_date, "user_type": $user_type, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all newsletter settings
#
# GET /newsletter_settings
# operationId: findNewsletterSettings
export def "newsletter-settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<newsletter_settings: table<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/newsletter_settings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a single newsletter settings if the user has access
#
# GET /newsletter_settings/{id}
# operationId: findNewsletterSettingsByID
export def "newsletter-settings find" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<newsletter_setting: record<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list<string>, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/newsletter_settings/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a single newsletter setting by ID
#
# PUT /newsletter_settings/{id}
# operationId: updateNewsletterSettingsByID
# --newsletter_setting shape: {_id: string, banner_color?: string, body_html?: string, email_accent_color?: string, email_day_of_week?: int, email_hour?: int, email_status?: string, facebook_active_wall?: string, footer_email_font?: string, footer_html?: string, footer_image_url?: string, group_id?: string, header_background_color?: string, header_image_url?: string, intro_text?: string, linkedin_active_wall?: string, montage_enabled?: bool, montage_facebook_image_url?: string, montage_linkedin_image_url?: string, ... (12 more fields)}
export def "newsletter-settings update" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --newsletter-setting: any # shape: {_id: string, banner_color?: string, body_html?: string, email_accent_color?: string, email_day_of_week?: int, email_hour?: int, email_status?: string, facebook_active_wall?: string, footer_email_font?: string, footer_html?: string, footer_image_url?: string, group_id?: string, header_background_color?: string, header_image_url?: string, intro_text?: string, linkedin_active_wall?: string, montage_enabled?: bool, montage_facebook_image_url?: string, montage_linkedin_image_url?: string, ... (12 more fields)}
]: any -> record<newsletter_setting: record<_id: string, banner_color: string, body_html: string, email_accent_color: string, email_day_of_week: int, email_hour: int, email_status: string, facebook_active_wall: string, footer_email_font: string, footer_html: string, footer_image_url: string, group_id: string, header_background_color: string, header_image_url: string, intro_text: string, linkedin_active_wall: string, montage_enabled: bool, montage_facebook_image_url: string, montage_linkedin_image_url: string, montage_title: string, montage_twitter_image_url: string, newsletter_ids: list<string>, newsletter_type: string, primary_email_font: string, salutation_text: string, social_day_of_week: int, social_description: string, social_posting_text: string, social_title: string, subject: string, title_color: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/newsletter_settings/{id}") $qp $auth.query)
  let req_body = {"newsletter_setting": $newsletter_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all newsletters
#
# GET /newsletters
# operationId: findNewsletters
export def "newsletters find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<newsletters: table<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/newsletters" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a newsletter by ID
#
# GET /newsletters/{id}
# operationId: getNewsletterByID
export def "newsletters get" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<newsletter: record<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/newsletters/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a newsletter
#
# PUT /newsletters/{id}
# operationId: updateNewsletterByID
export def "newsletters update" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --click-count: int # format: int64
  --is-default: oneof<nothing, bool>
  --is-sent: oneof<nothing, bool>
  --total-click-count: int # format: int64
  --unique-click-count: int # format: int64
]: any -> record<newsletter: record<_id: string, click_count: int, is_default: bool, is_sent: bool, total_click_count: int, unique_click_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/newsletters/{id}") $qp $auth.query)
  let req_body = {"click_count": $click_count, "is_default": $is_default, "is_sent": $is_sent, "total_click_count": $total_click_count, "unique_click_count": $unique_click_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Query all posts
#
# GET /posts
# operationId: findPosts
export def "posts find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --text-query: string # Filter post by parameters
  --external-url: string # Filter by External URL
  --is-published: string # Filter by is_published boolean
]: nothing -> record<posts: table<_id: string, advisor_id: string, approval_status: string, approval_transactions: list, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "text_query" $text_query "scalar") (serialize-qp "external_url" $external_url "scalar") (serialize-qp "is_published" $is_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token, "text_query": $text_query, "external_url": $external_url, "is_published": $is_published} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new post in the Vestorly Platform
#
# POST /posts
# operationId: createPost
export def "posts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --advisor-id: string
  --approval-status: string
  --approval-transactions: list<string>
  --article-id: string
  --comment: string
  --created-at: string
  --display-date: string
  --display-summary: string
  --display-tag: string
  --external-url: string
  --external-url-source: string
  --external-url-type: string
  --group-ids: list<string>
  --image-height: string
  --image-path: string
  --image-url: string
  --image-width: string
  --is-featured: oneof<nothing, bool>
  --is-mobile-proxy-needed: oneof<nothing, bool>
  --is-proxy-needed: oneof<nothing, bool>
  --is-published: oneof<nothing, bool>
  --is-responsive: oneof<nothing, bool>
  --logo-url: string
  --needs-sanitize: string
  --newsletter-ids: list<string>
  --post-date: string
  --proxy-url: string
  --slug: string
  --square-logo-url: string
  --suitability-score: string
  --summary: string
  title: string
  --topic: string
  --updated-at: string
  --vestorly-url: string
  --video: string
  --video-id: string
]: any -> record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts" $qp $auth.query)
  let req_body = {"advisor_id": $advisor_id, "approval_status": $approval_status, "approval_transactions": $approval_transactions, "article_id": $article_id, "comment": $comment, "created_at": $created_at, "display_date": $display_date, "display_summary": $display_summary, "display_tag": $display_tag, "external_url": $external_url, "external_url_source": $external_url_source, "external_url_type": $external_url_type, "group_ids": $group_ids, "image_height": $image_height, "image_path": $image_path, "image_url": $image_url, "image_width": $image_width, "is_featured": $is_featured, "is_mobile_proxy_needed": $is_mobile_proxy_needed, "is_proxy_needed": $is_proxy_needed, "is_published": $is_published, "is_responsive": $is_responsive, "logo_url": $logo_url, "needs_sanitize": $needs_sanitize, "newsletter_ids": $newsletter_ids, "post_date": $post_date, "proxy_url": $proxy_url, "slug": $slug, "square_logo_url": $square_logo_url, "suitability_score": $suitability_score, "summary": $summary, "title": $title, "topic": $topic, "updated_at": $updated_at, "vestorly_url": $vestorly_url, "video": $video, "video_id": $video_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Query all posts
#
# GET /posts/{id}
# operationId: getPostByID
export def "posts get" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/posts/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update A Post
#
# PUT /posts/{id}
# operationId: updatePostByID
export def "posts update" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --body-id: string
  --advisor-id: string
  --approval-status: string
  --approval-transactions: list<string>
  --article-id: string
  --comment: string
  --created-at: string
  --display-date: string
  --display-summary: string
  --display-tag: string
  --external-url: string
  --external-url-source: string
  --external-url-type: string
  --group-ids: list<string>
  --image-height: string
  --image-path: string
  --image-url: string
  --image-width: string
  --is-featured: oneof<nothing, bool>
  --is-mobile-proxy-needed: oneof<nothing, bool>
  --is-proxy-needed: oneof<nothing, bool>
  --is-published: oneof<nothing, bool>
  --is-responsive: oneof<nothing, bool>
  --logo-url: string
  --needs-sanitize: string
  --newsletter-ids: list<string>
  --post-date: string
  --proxy-url: string
  --redirector-link: string
  --slug: string
  --square-logo-url: string
  --suitability-score: string
  --summary: string
  --title: string
  --topic: string
  --updated-at: string
  --vestorly-url: string
  --video: string
  --video-id: string
]: any -> record<post: record<_id: string, advisor_id: string, approval_status: string, approval_transactions: list<string>, article_id: string, comment: string, created_at: string, display_date: string, display_summary: string, display_tag: string, external_url: string, external_url_source: string, external_url_type: string, group_ids: list<string>, image_height: string, image_path: string, image_url: string, image_width: string, is_featured: bool, is_mobile_proxy_needed: bool, is_proxy_needed: bool, is_published: bool, is_responsive: bool, logo_url: string, needs_sanitize: string, newsletter_ids: list<string>, post_date: string, proxy_url: string, redirector_link: string, slug: string, square_logo_url: string, suitability_score: string, summary: string, title: string, topic: string, updated_at: string, vestorly_url: string, video: string, video_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/posts/{id}") $qp $auth.query)
  let req_body = {"_id": $body_id, "advisor_id": $advisor_id, "approval_status": $approval_status, "approval_transactions": $approval_transactions, "article_id": $article_id, "comment": $comment, "created_at": $created_at, "display_date": $display_date, "display_summary": $display_summary, "display_tag": $display_tag, "external_url": $external_url, "external_url_source": $external_url_source, "external_url_type": $external_url_type, "group_ids": $group_ids, "image_height": $image_height, "image_path": $image_path, "image_url": $image_url, "image_width": $image_width, "is_featured": $is_featured, "is_mobile_proxy_needed": $is_mobile_proxy_needed, "is_proxy_needed": $is_proxy_needed, "is_published": $is_published, "is_responsive": $is_responsive, "logo_url": $logo_url, "needs_sanitize": $needs_sanitize, "newsletter_ids": $newsletter_ids, "post_date": $post_date, "proxy_url": $proxy_url, "redirector_link": $redirector_link, "slug": $slug, "square_logo_url": $square_logo_url, "suitability_score": $suitability_score, "summary": $summary, "title": $title, "topic": $topic, "updated_at": $updated_at, "vestorly_url": $vestorly_url, "video": $video, "video_id": $video_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all Categories keywords
#
# GET /seed_custom_feeds
# operationId: findSeedCustomFeeds
export def "seed-custom-feeds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<seed_custom_feeds: table<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list, seeds: list, sort_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/seed_custom_feeds" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Category Keyword
#
# POST /seed_custom_feeds
# operationId: createSeedCustomFeed
export def "seed-custom-feeds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --article-id: string
  custom_feed_id: string
  --not-article-id: string
  --not-seeds: list<string>
  --seeds: list<string>
  --sort-by: string
]: any -> record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/seed_custom_feeds" $qp $auth.query)
  let req_body = {"article_id": $article_id, "custom_feed_id": $custom_feed_id, "not_article_id": $not_article_id, "not_seeds": $not_seeds, "seeds": $seeds, "sort_by": $sort_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a Category keywords
#
# DELETE /seed_custom_feeds/{id}
# operationId: deleteSeedCustomFeed
export def "seed-custom-feeds delete" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/seed_custom_feeds/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns a single Category keyword
#
# GET /seed_custom_feeds/{id}
# operationId: findSeedCustomFeedByID
export def "seed-custom-feeds find" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/seed_custom_feeds/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a Category keywords
#
# PUT /seed_custom_feeds/{id}
# operationId: updateSeedCustomFeedById
export def "seed-custom-feeds update" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --article-id: string
  custom_feed_id: string
  --not-article-id: string
  --not-seeds: list<string>
  --seeds: list<string>
  --sort-by: string
]: any -> record<seed_custom_feed: record<_id: string, article_id: string, custom_feed_id: string, not_article_id: string, not_seeds: list<string>, seeds: list<string>, sort_by: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/seed_custom_feeds/{id}") $qp $auth.query)
  let req_body = {"article_id": $article_id, "custom_feed_id": $custom_feed_id, "not_article_id": $not_article_id, "not_seeds": $not_seeds, "seeds": $seeds, "sort_by": $sort_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Login To Vestorly Platform
#
# POST /sessions
# operationId: login
export def "sessions create-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username in the vestorly platform
  --password: string # Password in Vestorly Platform
]: nothing -> record<_id: string, current_user: record<_id: string, company: string, first_name: string, last_name: string, name: string, new_user: bool, picture_url: string, plan_expired: bool, plan_id: string, plan_setup: bool, plan_status: string, plan_stripe: bool, show_tour: bool, slug: string, user_type: string, username: string, website: string>, new_user: bool, settings: record<_id: string, adv_brochure: string, company: string, disclosure: string, feature: record<_id: string>, name: string, orgsetting: record<_id: string, company_address: string, company_contact_email: string, company_homepage_url: string, is_default: bool, name: string, privacy_policy_url: string, site_url: string, terms_and_conditions_url: string>, personalsetting: record<_id: string>, picture_url: string, slug: string, website: string>, vestorly_auth: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"username": $username, "password": $password} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Logout of the vestorly platform
#
# DELETE /sessions/{id}
# operationId: logout
export def "sessions delete-logout" [
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
  --vestorly-auth: string # Authenication token
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sessions/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns all sources
#
# GET /sources
# operationId: findSources
export def "sources find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<sources: table<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sources" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create source
#
# POST /sources
# operationId: createSource
export def "sources create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --custom-rss-feed: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --logo-url: string
  name: string
  rss_publisher: string
  url: string
]: any -> record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sources" $qp $auth.query)
  let req_body = {"custom_rss_feed": $custom_rss_feed, "enabled": $enabled, "logo_url": $logo_url, "name": $name, "rss_publisher": $rss_publisher, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Source By ID
#
# GET /sources/{id}
# operationId: getSourceByID
export def "sources get" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
]: nothing -> record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sources/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Source By ID
#
# PUT /sources/{id}
# operationId: updateSourceByID
export def "sources update" [
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
  --vestorly-auth: string # Vestorly Auth Token
  --access-token: string # OAuth Token
  --custom-rss-feed: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --logo-url: string
  name: string
  rss_publisher: string
  url: string
]: any -> record<source: record<_id: string, custom_rss_feed: bool, enabled: bool, logo_url: string, name: string, rss_publisher: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "vestorly_auth" $vestorly_auth "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sources/{id}") $qp $auth.query)
  let req_body = {"custom_rss_feed": $custom_rss_feed, "enabled": $enabled, "logo_url": $logo_url, "name": $name, "rss_publisher": $rss_publisher, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"vestorly_auth": $vestorly_auth, "access_token": $access_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}
