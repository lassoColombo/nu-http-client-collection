# Auto-generated client for Forem API V1 v1.0.0
# Source: https://api.apis.guru/v2/specs/dev.to/1.0.0/openapi.json
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
def state-completer [] { ["all" "fresh" "rising"] }
def display-to-completer [] { ["all" "logged_in" "logged_out"] }
def placement-area-completer [] { ["post_comments" "post_sidebar" "sidebar_left" "sidebar_left_2" "sidebar_right"] }
def type-of-completer [] { ["community" "external" "in_house"] }
def template-completer [] { ["contained" "full_within_layout" "json" "nav_bar_included"] }
def category-completer [] { ["exploding_head" "fire" "like" "raised_hands" "unicorn"] }
def reactable-type-completer [] { ["Article" "Comment" "User"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-users post" } } | get name | first)
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
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tags_exclude" $tags_exclude "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "collection_id" $collection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish article
#
# POST /api/articles
# operationId: createArticle
# --article shape: {body_markdown?: string, canonical_url?: string, description?: string, main_image?: string, organization_id?: int, published?: bool, series?: string, tags?: string, title?: string}
export def "articles createArticle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --article: record # shape: {body_markdown?: string, canonical_url?: string, description?: string, main_image?: string, organization_id?: int, published?: bool, series?: string, tags?: string, title?: string}
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
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/latest" $qp)
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
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/me" $qp)
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
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/me/all" $qp)
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
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
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
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/articles/me/unpublished" $qp)
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
# --article shape: {body_markdown?: string, canonical_url?: string, description?: string, main_image?: string, organization_id?: int, published?: bool, series?: string, tags?: string, title?: string}
export def "articles updateArticle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --article: record # shape: {body_markdown?: string, canonical_url?: string, description?: string, main_image?: string, organization_id?: int, published?: bool, series?: string, tags?: string, title?: string}
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
  --a-id: string # Article identifier. (e.g. 321)
  --p-id: string # Podcast Episode identifier. (e.g. 321)
]: nothing -> table<created_at: string, id_code: string, image_url: string, type_of: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "a_id" $a_id "scalar") (serialize-qp "p_id" $p_id "scalar")] | flatten | str join "&"
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

# display ads
#
# GET /api/display_ads
export def "display-ads list" [
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
  let full_url = (build-url $base "/api/display_ads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# display ads
#
# POST /api/display_ads
export def "display-ads post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approved: string@bool-completer # Ad must be both published and approved to be in rotation
  body_markdown: string # The text (in markdown) of the ad (required)
  --creator-id: int # Identifies the user who created the ad.
  --display-to: string@display-to-completer # Potentially limits visitors to whom the ad is visible (default: all)
  name: string # For internal use, helps distinguish ads from one another
  --organization-id: int # Identifies the organization to which the ad belongs
  placement_area: string@placement-area-completer # Identifies which area of site layout the ad can appear in
  --published: string@bool-completer # Ad must be both published and approved to be in rotation
  --tag-list: string # Tags on which this ad can be displayed (blank is all/any tags)
  --type-of: string@type-of-completer # Types of the billboards: in_house (created by admins), community (created by an entity, appears on entity's content), external ( created by an entity, or a non-entity, can appear everywhere)  (default: in_house)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/display_ads")
  let body = {approved: $approved, body_markdown: $body_markdown, creator_id: $creator_id, display_to: $display_to, name: $name, organization_id: $organization_id, placement_area: $placement_area, published: $published, tag_list: $tag_list, type_of: $type_of} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# display ad
#
# GET /api/display_ads/{id}
export def "display-ads get" [
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
  let full_url = (build-url $base $"/api/display_ads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# display ads
#
# PUT /api/display_ads/{id}
export def "display-ads put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approved: string@bool-completer # Ad must be both published and approved to be in rotation
  body_markdown: string # The text (in markdown) of the ad (required)
  --creator-id: int # Identifies the user who created the ad.
  --display-to: string@display-to-completer # Potentially limits visitors to whom the ad is visible (default: all)
  name: string # For internal use, helps distinguish ads from one another
  --organization-id: int # Identifies the organization to which the ad belongs, required for 'community' type ads
  placement_area: string@placement-area-completer # Identifies which area of site layout the ad can appear in
  --published: string@bool-completer # Ad must be both published and approved to be in rotation
  --tag-list: string # Tags on which this ad can be displayed (blank is all/any tags)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/display_ads/($id)")
  let body = {approved: $approved, body_markdown: $body_markdown, creator_id: $creator_id, display_to: $display_to, name: $name, organization_id: $organization_id, placement_area: $placement_area, published: $published, tag_list: $tag_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# unpublish
#
# PUT /api/display_ads/{id}/unpublish
export def "display-ads-unpublish put" [
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
  let full_url = (build-url $base $"/api/display_ads/($id)/unpublish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<id: int, name: string, path: string, profile_image: string, type_of: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/followers/users" $qp)
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

# An organization
#
# GET /api/organizations/{username}
# operationId: getOrganization
export def "organizations get" [
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

# Organization's Articles
#
# GET /api/organizations/{username}/articles
# operationId: getOrgArticles
export def "organizations-articles get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/organizations/($username)/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organization's users
#
# GET /api/organizations/{username}/users
# operationId: getOrgUsers
export def "organizations-users get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination page (format: int32, default: 1)
  --per-page: int # Page size (the number of items to return per page). The default maximum value can be overridden by "API_PER_PAGE_MAX" environment variable. (format: int32, default: 30)
]: nothing -> table<github_username: string, id: int, joined_at: string, location: string, name: string, profile_image: string, summary: string, twitter_username: string, type_of: string, username: string, website_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/organizations/($username)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string> {
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
  --body-json: string # For JSON pages, the JSON body
  --body-markdown: string # The text (in markdown) of the ad (required)
  --description: string # For internal use, helps similar pages from one another
  --is-top-level-path: string@bool-completer # If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution
  --slug: string # Used to link to this page in URLs, must be unique and URL-safe
  --template: string@template-completer # Controls what kind of layout the page is rendered in (default: contained)
  --title: string # Title of the page
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/pages")
  let body = {body_json: $body_json, body_markdown: $body_markdown, description: $description, is_top_level_path: $is_top_level_path, slug: $slug, template: $template, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string> {
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
  --body-json: string # For JSON pages, the JSON body (nullable)
  --body-markdown: string # The text (in markdown) of the ad (required) (nullable)
  description: string # For internal use, helps similar pages from one another
  --is-top-level-path: string@bool-completer # If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution
  slug: string # Used to link to this page in URLs, must be unique and URL-safe
  --social-image: record # nullable
  template: string@template-completer # Controls what kind of layout the page is rendered in (default: contained)
  title: string # Title of the page
]: any -> record<body_json: string, body_markdown: string, description: string, is_top_level_path: bool, slug: string, social_image: record, template: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/pages/($id)")
  let body = {body_json: $body_json, body_markdown: $body_markdown, description: $description, is_top_level_path: $is_top_level_path, slug: $slug, social_image: $social_image, template: $template, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> table<class_name: string, id: int, image_url: string, path: string, podcast: record<image_url: string, slug: string, title: string>, title: string, type_of: string> {
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
]: nothing -> table<canonical_url: string, cover_image: string, created_at: string, crossposted_at: string, description: string, edited_at: string, flare_tag: record<bg_color_hex: string, name: string, text_color_hex: string>, id: int, last_comment_at: string, organization: record<name: string, profile_image: string, profile_image_90: string, slug: string, username: string>, path: string, positive_reactions_count: int, public_reactions_count: int, published_at: string, published_timestamp: string, readable_publish_date: string, reading_time_minutes: int, slug: string, social_image: string, tag_list: list<string>, tags: string, title: string, type_of: string, url: string, user: record<github_username: string, name: string, profile_image: string, profile_image_90: string, twitter_username: string, username: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/readinglist" $qp)
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
]: nothing -> table<bg_color_hex: string, id: int, name: string, text_color_hex: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<cloudinary_video_url: string, id: int, path: string, title: string, type_of: string, user: record<name: string>, user_id: int, video_duration_in_minutes: string, video_source_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
