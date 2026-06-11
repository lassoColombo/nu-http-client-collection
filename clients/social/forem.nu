# Auto-generated client for Forem API V1 v1.0.0
# Source: https://raw.githubusercontent.com/forem/forem/main/swagger/v1/api_v1.json
# Auth: --token flag or $env.FOREM_API_V1_TOKEN

const BASE_URL = "https://dev.to/api"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FOREM_API_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {api-key: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://dev.to/api"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def tool-name-completer [] { ["claude_code" "codex" "gemini_cli" "github_copilot" "opencode" "pi"] }
def state-completer [] { ["all" "fresh" "rising"] }
def template-completer [] { ["contained" "css" "full_within_layout" "json" "nav_bar_included" "txt"] }
def category-completer [] { ["exploding_head" "fire" "like" "raised_hands" "unicorn"] }
def reactable-type-completer [] { ["Article" "Comment" "User"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "agent-sessions list" } } | get name | first)
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

# list the authenticated user's agent sessions
#
# GET /api/agent_sessions
# operationId: getAgentSessions
export def "agent-sessions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, slug: string, title: string, tool_name: string, total_messages: int, published: bool, created_at: string, updated_at: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# upload a new agent session
#
# POST /api/agent_sessions
# operationId: createAgentSession
export def "agent-sessions createAgentSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title for the session (auto-generated if omitted)
  curated_data: string # JSON string of curated session data with messages array and metadata.
  --s3-key: string # S3 object key from presign endpoint (optional).
  --tool-name: string@tool-name-completer # Tool that produced the session (e.g. claude_code, codex).
]: any -> record<id: int, slug: string, title: string, tool_name: string, total_messages: int, published: bool, created_at: string, updated_at: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/agent_sessions")
  let body = {title: $title, curated_data: $curated_data, s3_key: $s3_key, tool_name: $tool_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# show details for an agent session
#
# GET /api/agent_sessions/{id}
# operationId: getAgentSessionById
export def "agent-sessions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, slug: string, title: string, tool_name: string, total_messages: int, curated_count: int, published: bool, metadata: record, messages: list<record>, slices: list<record>, created_at: string, updated_at: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/agent_sessions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish article
#
# POST /api/articles
# operationId: createArticle
# --article shape: {title?: string, body_markdown?: string, published?: bool, series?: string, main_image?: string, canonical_url?: string, description?: string, tags?: string, organization_id?: int}
export def "articles createArticle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --article: record # shape: {title?: string, body_markdown?: string, published?: bool, series?: string, main_image?: string, canonical_url?: string, description?: string, tags?: string, organization_id?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/articles")
  let body = {article: $article} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Published articles
#
# GET /api/articles
# operationId: getArticles
export def "articles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --tag: string # Using this parameter will retrieve articles that contain the requested tag. Articles will be ordered by descending popularity.This parameter can be used in conjuction with `top`. (e.g. discuss)
  --tags: string # Using this parameter will retrieve articles with any of the comma-separated tags. Articles will be ordered by descending popularity. (e.g. javascript, css)
  --tags-exclude: string # Using this parameter will retrieve articles that do _not_ contain _any_ of comma-separated tags. Articles will be ordered by descending popularity. (e.g. node, java)
  --username: string # Using this parameter will retrieve articles belonging             to a User or Organization ordered by descending publication date.             If `state=all` the number of items returned will be `1000` instead of the default `30`.             This parameter can be used in conjuction with `state`. (e.g. ben)
  --state: string@state-completer # Using this parameter will allow the client to check which articles are fresh or rising.             If `state=fresh` the server will return fresh articles.             If `state=rising` the server will return rising articles.             This param can be used in conjuction with `username`, only if set to `all`. (e.g. fresh)
  --top: int # Using this parameter will allow the client to return the most popular articles in the last `N` days. `top` indicates the number of days since publication of the articles returned. This param can be used in conjuction with `tag`. (format: int32, e.g. 2)
  --collection-id: int # Adding this will allow the client to return the list of articles belonging to the requested collection, ordered by ascending publication date. (format: int32, e.g. 99)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tags_exclude" $tags_exclude "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "collection_id" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Published articles sorted by published date
#
# GET /api/articles/latest
# operationId: getLatestArticles
export def "articles-latest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Published article by id
#
# GET /api/articles/{id}
# operationId: getArticleById
export def "articles get-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/articles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an article by id
#
# PUT /api/articles/{id}
# operationId: updateArticle
# --article shape: {title?: string, body_markdown?: string, published?: bool, series?: string, main_image?: string, canonical_url?: string, description?: string, tags?: string, organization_id?: int}
export def "articles updateArticle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --article: record # shape: {title?: string, body_markdown?: string, published?: bool, series?: string, main_image?: string, canonical_url?: string, description?: string, tags?: string, organization_id?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/articles/($id)")
  let body = {article: $article} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Published article by path
#
# GET /api/articles/{username}/{slug}
# operationId: getArticleByPath
export def "articles get-by-username-slug" [
  username: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/articles/($username)/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User's articles
#
# GET /api/articles/me
# operationId: getUserArticles
export def "articles-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User's published articles
#
# GET /api/articles/me/published
# operationId: getUserPublishedArticles
export def "articles-me-published get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/me/published" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User's unpublished articles
#
# GET /api/articles/me/unpublished
# operationId: getUserUnpublishedArticles
export def "articles-me-unpublished get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/me/unpublished" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User's all articles
#
# GET /api/articles/me/all
# operationId: getUserAllArticles
export def "articles-me-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/me/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpublish an article
#
# PUT /api/articles/{id}/unpublish
# operationId: unpublishArticle
export def "articles-unpublish unpublishArticle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # Content for the note that's created along with unpublishing (e.g. Admin requested unpublishing all articles via API)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "note" $note "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/articles/($id)/unpublish" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manually managed audience segments
#
# GET /api/segments
# operationId: getSegments
export def "segments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<id: int, type_of: string, user_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a manually managed audience segment
#
# POST /api/segments
# operationId: createSegment
export def "segments createSegment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/segments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# A manually managed audience segment
#
# GET /api/segments/{id}
# operationId: getSegment
export def "segments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/segments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a manually managed audience segment
#
# DELETE /api/segments/{id}
# operationId: deleteSegment
export def "segments delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/segments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Users in a manually managed audience segment
#
# GET /api/segments/{id}/users
# operationId: getUsersInSegment
export def "segments-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, username: string, name: string, summary: string, twitter_username: string, github_username: string, website_url: string, location: string, joined_at: string, profile_image: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/segments/($id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add users to a manually managed audience segment
#
# PUT /api/segments/{id}/add_users
# operationId: addUsersToSegment
export def "segments-add-users addUsersToSegment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-ids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/segments/($id)/add_users")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove users from a manually managed audience segment
#
# PUT /api/segments/{id}/remove_users
# operationId: removeUsersFromSegment
export def "segments-remove-users removeUsersFromSegment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-ids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/segments/($id)/remove_users")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Billboards
#
# GET /api/billboards
export def "billboards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, body_markdown: string, approved: bool, published: bool, expires_at: string, organization_id: int, creator_id: int, placement_area: string, tag_list: string, exclude_article_ids: string, audience_segment_id: int, audience_segment_type: string, target_geolocations: list<string>, display_to: string, type_of: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/billboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a billboard
#
# POST /api/billboards
export def "billboards post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/billboards")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# A billboard (by id)
#
# GET /api/billboards/{id}
export def "billboards get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a billboard by ID
#
# PUT /api/billboards/{id}
export def "billboards put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billboards/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unpublish a billboard
#
# PUT /api/billboards/{id}/unpublish
export def "billboards-unpublish put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billboards/($id)/unpublish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Comments
#
# GET /api/comments
# operationId: getCommentsByArticleId
export def "comments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --a-id: string # Article identifier. (e.g. 321)
  --p-id: string # Podcast Episode identifier. (e.g. 321)
  --page: string # Page (e.g. 321)
]: nothing -> table<type_of: string, id_code: string, created_at: string, image_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "a_id" $a_id "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Comment by id
#
# GET /api/comments/{id}
# operationId: getCommentById
export def "comments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/comments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Followed Tags
#
# GET /api/follows/tags
# operationId: getFollowedTags
export def "follows-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, points: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/follows/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Followers
#
# GET /api/followers/users
# operationId: getFollowers
export def "followers-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --qp-sort: string # Default is 'created_at'. Specifies the sort order for the created_at param of the follow                                 relationship. To sort by newest followers first (descending order) specify                                 ?sort=-created_at. (e.g. created_at)
]: nothing -> table<type_of: string, id: int, user_id: int, name: string, path: string, profile_image: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/followers/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# An organization (by username)
#
# GET /api/organizations/{username}
# operationId: getOrganization
export def "organizations get-by-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/organizations/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization's users
#
# GET /api/organizations/{organization_id_or_username}/users
# operationId: getOrgUsers
export def "organizations-users get" [
  organization_id_or_username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, username: string, name: string, summary: string, twitter_username: string, github_username: string, website_url: string, location: string, joined_at: string, profile_image: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/organizations/($organization_id_or_username)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization's Articles
#
# GET /api/organizations/{organization_id_or_username}/articles
# operationId: getOrgArticles
export def "organizations-articles get" [
  organization_id_or_username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/organizations/($organization_id_or_username)/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organizations
#
# GET /api/organizations
# operationId: getOrganizations
export def "organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 10)
]: nothing -> table<type_of: string, username: string, name: string, summary: string, twitter_username: string, github_username: string, url: string, location: string, joined_at: string, tech_stack: string, tag_line: string, story: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Organization
#
# POST /api/organizations
# operationId: createOrganization
export def "organizations createOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type-of: string
  --username: string
  --name: string
  --summary: string
  --twitter-username: string
  --github-username: string
  --body-url: string
  --location: string
  --joined-at: string
  --tech-stack: string
  --tag-line: string # nullable
  --story: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/organizations")
  let body = {type_of: $type_of, username: $username, name: $name, summary: $summary, twitter_username: $twitter_username, github_username: $github_username, url: $body_url, location: $location, joined_at: $joined_at, tech_stack: $tech_stack, tag_line: $tag_line, story: $story} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# An organization (by id)
#
# GET /api/organizations/{id}
# operationId: getOrganizationById
export def "organizations get-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization by id
#
# PUT /api/organizations/{id}
export def "organizations put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type-of: string
  --username: string
  --name: string
  --summary: string
  --twitter-username: string
  --github-username: string
  --body-url: string
  --location: string
  --joined-at: string
  --tech-stack: string
  --tag-line: string # nullable
  --story: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/organizations/($id)")
  let body = {type_of: $type_of, username: $username, name: $name, summary: $summary, twitter_username: $twitter_username, github_username: $github_username, url: $body_url, location: $location, joined_at: $joined_at, tech_stack: $tech_stack, tag_line: $tag_line, story: $story} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Organization by id
#
# DELETE /api/organizations/{id}
export def "organizations delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# show details for all pages
#
# GET /api/pages
export def "pages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<title: string, slug: string, description: string, body_markdown: string, body_json: string, is_top_level_path: bool, social_image: record, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# pages
#
# POST /api/pages
export def "pages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of the page
  --slug: string # Used to link to this page in URLs, must be unique and URL-safe
  --description: string # For internal use, helps similar pages from one another
  --body-markdown: string # The text (in markdown) of the ad (required)
  --body-json: string # For JSON pages, the JSON body
  --is-top-level-path: string@bool-completer # If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution
  --template: string@template-completer # Controls what kind of layout the page is rendered in (default: contained)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pages")
  let body = {title: $title, slug: $slug, description: $description, body_markdown: $body_markdown, body_json: $body_json, is_top_level_path: $is_top_level_path, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# show details for a page
#
# GET /api/pages/{id}
export def "pages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<title: string, slug: string, description: string, body_markdown: string, body_json: string, is_top_level_path: bool, social_image: record, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# update details for a page
#
# PUT /api/pages/{id}
export def "pages put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Title of the page
  slug: string # Used to link to this page in URLs, must be unique and URL-safe
  description: string # For internal use, helps similar pages from one another
  --body-markdown: string # The text (in markdown) of the ad (required) (nullable)
  --body-json: string # For JSON pages, the JSON body (nullable)
  --is-top-level-path: string@bool-completer # If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution
  --social-image: record # nullable
  template: string@template-completer # Controls what kind of layout the page is rendered in (default: contained)
]: any -> record<title: string, slug: string, description: string, body_markdown: string, body_json: string, is_top_level_path: bool, social_image: record, template: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pages/($id)")
  let body = {title: $title, slug: $slug, description: $description, body_markdown: $body_markdown, body_json: $body_json, is_top_level_path: $is_top_level_path, social_image: $social_image, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# remove a page
#
# DELETE /api/pages/{id}
export def "pages delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<title: string, slug: string, description: string, body_markdown: string, body_json: string, is_top_level_path: bool, social_image: record, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Podcast Episodes
#
# GET /api/podcast_episodes
# operationId: getPodcastEpisodes
export def "podcast-episodes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --username: string # Using this parameter will retrieve episodes belonging to a specific podcast. (e.g. codenewbie)
]: nothing -> table<type_of: string, id: int, class_name: string, path: string, title: string, image_url: string, podcast: record<title: string, slug: string, image_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/podcast_episodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# A Users or organizations profile image
#
# GET /api/profile_images/{username}
# operationId: getProfileImage
export def "profile-images get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/profile_images/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# toggle reaction
#
# POST /api/reactions/toggle
export def "reactions-toggle post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category: string@category-completer
  --reactable-id: int # format: int32
  --reactable-type: string@reactable-type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "reactable_id" $reactable_id "scalar") (serialize-qp "reactable_type" $reactable_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/reactions/toggle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# create reaction
#
# POST /api/reactions
export def "reactions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category: string@category-completer
  --reactable-id: int # format: int32
  --reactable-type: string@reactable-type-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "reactable_id" $reactable_id "scalar") (serialize-qp "reactable_type" $reactable_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/reactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Readinglist
#
# GET /api/readinglist
# operationId: getReadinglist
export def "readinglist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/readinglist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List surveys
#
# GET /api/surveys
# operationId: getSurveys
export def "surveys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --active: string@bool-completer # Filter by active status. Omit to return all surveys.
]: nothing -> table<type_of: string, id: int, title: string, slug: string, survey_type_of: string, active: bool, display_title: bool, allow_resubmission: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/surveys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# A survey with polls
#
# GET /api/surveys/{id_or_slug}
# operationId: getSurveyByIdOrSlug
export def "surveys get" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type_of: string, id: int, title: string, slug: string, survey_type_of: string, active: bool, display_title: bool, allow_resubmission: bool, created_at: string, updated_at: string, polls: table<type_of: string, id: int, prompt_markdown: string, prompt_html: string, poll_type_of: string, position: int, poll_votes_count: int, poll_skips_count: int, poll_options_count: int, scale_min: int, scale_max: int, created_at: string, updated_at: string, poll_options: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/surveys/($id_or_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Survey poll votes
#
# GET /api/surveys/{id_or_slug}/poll_votes
# operationId: getSurveyPollVotes
export def "surveys-poll-votes get" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --after: int # Return only votes with an ID greater than this value. (e.g. 42)
]: nothing -> table<type_of: string, id: int, poll_id: int, poll_option_id: int, user_id: int, user_email: string, session_start: int, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/surveys/($id_or_slug)/poll_votes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Survey poll text responses
#
# GET /api/surveys/{id_or_slug}/poll_text_responses
# operationId: getSurveyPollTextResponses
export def "surveys-poll-text-responses get" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
  --after: int # Return only text responses with an ID greater than this value. (e.g. 42)
]: nothing -> table<type_of: string, id: int, poll_id: int, user_id: int, user_email: string, text_content: string, session_start: int, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/surveys/($id_or_slug)/poll_text_responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tags
#
# GET /api/tags
# operationId: getTags
export def "tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 10)
]: nothing -> table<id: int, name: string, bg_color_hex: string, text_color_hex: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trends
#
# GET /api/trends
# operationId: getTrends
export def "trends list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 10)
]: nothing -> table<type_of: string, id: int, name: string, slug: string, description: string, key_questions: list<string>, score: float, articles_count: int, cover_image: string, first_observed_at: string, last_observed_at: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/trends" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# A Trend
#
# GET /api/trends/{id_or_slug}
# operationId: getTrend
export def "trends get" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/trends/($id_or_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Articles in a Trend
#
# GET /api/trends/{trend_id_or_slug}/articles
# operationId: getTrendArticles
export def "trends-articles get" [
  trend_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 10)
]: nothing -> table<type_of: string, id: int, title: string, description: string, cover_image: string, readable_publish_date: string, social_image: string, tag_list: list<string>, tags: string, slug: string, path: string, url: string, canonical_url: string, positive_reactions_count: int, public_reactions_count: int, created_at: string, edited_at: string, crossposted_at: string, published_at: string, last_comment_at: string, published_timestamp: string, reading_time_minutes: int, user: record<name: string, username: string, twitter_username: string, github_username: string, website_url: string, profile_image: string, profile_image_90: string>, flare_tag: record<name: string, bg_color_hex: string, text_color_hex: string>, organization: record<name: string, username: string, slug: string, profile_image: string, profile_image_90: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/trends/($trend_id_or_slug)/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspend a User
#
# PUT /api/users/{id}/suspend
# operationId: suspendUser
export def "users-suspend suspendUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add limited role for a User
#
# PUT /api/users/{id}/limited
# operationId: limitUser
export def "users-limited limitUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/limited")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove limited for a User
#
# DELETE /api/users/{id}/limited
# operationId: unLimitUser
export def "users-limited unLimitUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/limited")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add spam role for a User
#
# PUT /api/users/{id}/spam
# operationId: spamUser
export def "users-spam spamUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/spam")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove spam role from a User
#
# DELETE /api/users/{id}/spam
# operationId: unSpamUser
export def "users-spam unSpamUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/spam")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add trusted role for a User
#
# PUT /api/users/{id}/trusted
# operationId: trustUser
export def "users-trusted trustUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/trusted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove trusted role from a User
#
# DELETE /api/users/{id}/trusted
# operationId: unTrustUser
export def "users-trusted unTrustUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/trusted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The authenticated user
#
# GET /api/users/me
# operationId: getUserMe
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# A User
#
# GET /api/users/{id}
# operationId: getUser
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpublish a User's Articles and Comments
#
# PUT /api/users/{id}/unpublish
# operationId: unpublishUser
export def "users-unpublish unpublishUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/unpublish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite a User
#
# POST /api/admin/users
# operationId: postAdminUsersCreate
export def "admin-users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --name: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/users")
  let body = {email: $email, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Articles with a video
#
# GET /api/videos
# operationId: videos
export def "videos videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 24)
]: nothing -> table<type_of: string, id: int, path: string, cloudinary_video_url: string, title: string, user_id: int, video_duration_in_minutes: string, video_source_url: string, user: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
