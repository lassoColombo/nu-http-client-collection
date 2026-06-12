# Auto-generated client for Notion API v1.0.0
# Source: https://developers.notion.com/openapi.json
# Auth: --token flag or $env.NOTION_API_TOKEN

const BASE_URL = "https://api.notion.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOTION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.notion.com"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def Notion-Version-completer [] { ["2026-03-11"] }
def result-type-completer [] { ["data_source" "page"] }
def mode-completer [] { ["external_url" "multi_part" "single_part"] }
def status-completer [] { ["expired" "failed" "pending" "uploaded"] }
def type-completer [] { ["board" "calendar" "chart" "dashboard" "form" "gallery" "list" "map" "table" "timeline"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "users-me get-self" } } | get name | first)
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

# Retrieve your token's bot user
#
# GET /v1/users/me
# operationId: get-self
export def "users-me get-self" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<id: string, object: string, name: any, avatar_url: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/me")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a user
#
# GET /v1/users/{user_id}
# operationId: get-user
export def "users get-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<id: string, object: string, name: any, avatar_url: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all users
#
# GET /v1/users
# operationId: get-users
export def "users get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-cursor: string
  --page-size: float
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<type: string, user: record, object: string, next_cursor: string, has_more: bool, results: table<id: string, object: string, name: any, avatar_url: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a page
#
# POST /v1/pages
# operationId: post-page
export def "pages post-page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --parent: any
  --properties: record
  --icon: any
  --cover: any
  --content: list
  --children: list
  --markdown: string # Page content as Notion-flavored Markdown. Mutually exclusive with content/children.
  --template: any
  --position: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pages")
  let body = {parent: $parent, properties: $properties, icon: $icon, cover: $cover, content: $content, children: $children, markdown: $markdown, template: $template, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a page
#
# GET /v1/pages/{page_id}
# operationId: retrieve-a-page
export def "pages retrieve-a-page" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-properties: list
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_properties" $filter_properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/pages/($page_id)" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update page
#
# PATCH /v1/pages/{page_id}
# operationId: patch-page
export def "pages patch-page" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --properties: record
  --icon: any
  --cover: any
  --is-locked: oneof<nothing, bool> # Whether the page should be locked from editing in the Notion app UI. If not provided, the locked state will not be updated.
  --template: any
  --erase-content: oneof<nothing, bool> # Whether to erase all existing content from the page. When used with a template, the template content replaces the existing content. When used without a template, simply clears the page content.
  --in-trash: oneof<nothing, bool>
  --is-archived: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pages/($page_id)")
  let body = {properties: $properties, icon: $icon, cover: $cover, is_locked: $is_locked, template: $template, erase_content: $erase_content, in_trash: $in_trash, is_archived: $is_archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Move a page
#
# POST /v1/pages/{page_id}/move
# operationId: move-page
export def "pages-move move-page" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  parent: any # The new parent of the page.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pages/($page_id)/move")
  let body = {parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a page property item
#
# GET /v1/pages/{page_id}/properties/{property_id}
# operationId: retrieve-a-page-property
export def "pages-properties retrieve-a-page-property" [
  page_id: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-cursor: string
  --page-size: int
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/pages/($page_id)/properties/($property_id)" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a page as markdown
#
# GET /v1/pages/{page_id}/markdown
# operationId: retrieve-page-markdown
export def "pages-markdown retrieve-page-markdown" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-transcript: oneof<nothing, bool>
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, id: string, markdown: string, truncated: bool, unknown_block_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_transcript" $include_transcript "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/pages/($page_id)/markdown" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a page's content as markdown
#
# PATCH /v1/pages/{page_id}/markdown
# operationId: update-page-markdown
# --insert_content shape: {content: string, after?: string, position?: any}
# --replace_content_range shape: {content: string, content_range: string, allow_deleting_content?: bool}
# --update_content shape: {content_updates: list, allow_deleting_content?: bool}
# --replace_content shape: {new_str: string, allow_deleting_content?: bool}
export def "pages-markdown update-page-markdown" [
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --type: string # Always `insert_content`
  --insert-content: record # Insert new content into the page. — shape: {content: string, after?: string, position?: any}
  --replace-content-range: record # Replace a range of content in the page. — shape: {content: string, content_range: string, allow_deleting_content?: bool}
  --update-content: record # Update specific content using search-and-replace operations. — shape: {content_updates: list, allow_deleting_content?: bool}
  --replace-content: record # Replace the entire page content with new markdown. — shape: {new_str: string, allow_deleting_content?: bool}
]: any -> record<object: string, id: string, markdown: string, truncated: bool, unknown_block_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pages/($page_id)/markdown")
  let body = {type: $type, insert_content: $insert_content, replace_content_range: $replace_content_range, update_content: $update_content, replace_content: $replace_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a block
#
# GET /v1/blocks/{block_id}
# operationId: retrieve-a-block
export def "blocks retrieve-a-block" [
  block_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($block_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a block
#
# PATCH /v1/blocks/{block_id}
# operationId: update-a-block
export def "blocks update-a-block" [
  block_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --in-trash: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($block_id)")
  let body = {in_trash: $in_trash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a block
#
# DELETE /v1/blocks/{block_id}
# operationId: delete-a-block
export def "blocks delete-a-block" [
  block_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($block_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve block children
#
# GET /v1/blocks/{block_id}/children
# operationId: get-block-children
export def "blocks-children get-block-children" [
  block_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-cursor: string # format: uuid
  --page-size: float
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<type: string, block: record, object: string, next_cursor: string, has_more: bool, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/blocks/($block_id)/children" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Append block children
#
# PATCH /v1/blocks/{block_id}/children
# operationId: patch-block-children
export def "blocks-children patch-block-children" [
  block_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  children: list
  --position: any
]: any -> record<type: string, block: record, object: string, next_cursor: string, has_more: bool, results: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($block_id)/children")
  let body = {children: $children, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a data source
#
# GET /v1/data_sources/{data_source_id}
# operationId: retrieve-a-data-source
export def "data-sources retrieve-a-data-source" [
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/data_sources/($data_source_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a data source
#
# PATCH /v1/data_sources/{data_source_id}
# operationId: update-a-data-source
# --title item shape: {annotations?: record}
# --parent shape: {type?: string, database_id: string}
export def "data-sources update-a-data-source" [
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --title: list # Title of data source as it appears in Notion. — item shape: {annotations?: record}
  --icon: any # Page icon.
  --properties: record # The property schema of the data source. The keys are property names or IDs, and the values are property configuration objects. Properties set to null will be removed.
  --in-trash: oneof<nothing, bool> # Whether the database should be moved to or from the trash. If not provided, the trash status will not be updated.
  --parent: record # shape: {type?: string, database_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/data_sources/($data_source_id)")
  let body = {title: $title, icon: $icon, properties: $properties, in_trash: $in_trash, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query a data source
#
# POST /v1/data_sources/{data_source_id}/query
# operationId: post-database-query
export def "data-sources-query post-database-query" [
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-properties: list
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --sorts: list
  --filter: any
  --start-cursor: string
  --page-size: float
  --in-trash: oneof<nothing, bool>
  --result-type: string@result-type-completer # Optionally filter the results to only include pages or data sources. Regular, non-wiki databases only support page children. The default behavior is no result type filtering, in other words, returning both pages and data sources for wikis.
]: any -> record<type: string, page_or_data_source: record, object: string, next_cursor: string, has_more: bool, results: list<any>, request_status: record<type: string, incomplete_reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_properties" $filter_properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/data_sources/($data_source_id)/query" $qp)
  let body = {sorts: $sorts, filter: $filter, start_cursor: $start_cursor, page_size: $page_size, in_trash: $in_trash, result_type: $result_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a data source
#
# POST /v1/data_sources
# operationId: create-a-database
# --parent shape: {type?: string, database_id: string}
# --title item shape: {annotations?: record}
export def "data-sources create-a-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  parent: record # shape: {type?: string, database_id: string}
  properties: record # Property schema of data source.
  --title: list # Title of data source as it appears in Notion. — item shape: {annotations?: record}
  --icon: any # Page icon.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/data_sources")
  let body = {parent: $parent, properties: $properties, title: $title, icon: $icon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List templates in a data source
#
# GET /v1/data_sources/{data_source_id}/templates
# operationId: list-data-source-templates
export def "data-sources-templates list-data-source-templates" [
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --start-cursor: string
  --page-size: int
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<templates: table<id: string, name: string, is_default: bool>, has_more: bool, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/data_sources/($data_source_id)/templates" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a database
#
# GET /v1/databases/{database_id}
# operationId: retrieve-database
export def "databases retrieve-database" [
  database_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/databases/($database_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a database
#
# PATCH /v1/databases/{database_id}
# operationId: update-database
# --title item shape: {annotations?: record}
# --description item shape: {annotations?: record}
export def "databases update-database" [
  database_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --parent: any # The parent page or workspace to move the database to. If not provided, the database will not be moved.
  --title: list # The updated title of the database, if any. If not provided, the title will not be updated. — item shape: {annotations?: record}
  --description: list # The updated description of the database, if any. If not provided, the description will not be updated. — item shape: {annotations?: record}
  --is-inline: oneof<nothing, bool> # Whether the database should be displayed inline in the parent page. If not provided, the inline status will not be updated.
  --icon: any
  --cover: any
  --in-trash: oneof<nothing, bool> # Whether the database should be moved to or from the trash. If not provided, the trash status will not be updated.
  --is-locked: oneof<nothing, bool> # Whether the database should be locked from editing in the Notion app UI. If not provided, the locked state will not be updated.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/databases/($database_id)")
  let body = {parent: $parent, title: $title, description: $description, is_inline: $is_inline, icon: $icon, cover: $cover, in_trash: $in_trash, is_locked: $is_locked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a database
#
# POST /v1/databases
# operationId: create-database
# --title item shape: {annotations?: record}
# --description item shape: {annotations?: record}
# --initial_data_source shape: {properties?: record}
export def "databases create-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  parent: any # The parent page or workspace where the database will be created.
  --title: list # The title of the database. — item shape: {annotations?: record}
  --description: list # The description of the database. — item shape: {annotations?: record}
  --is-inline: oneof<nothing, bool> # Whether the database should be displayed inline in the parent page. Defaults to false.
  --initial-data-source: record # shape: {properties?: record}
  --icon: any
  --cover: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/databases")
  let body = {parent: $parent, title: $title, description: $description, is_inline: $is_inline, initial_data_source: $initial_data_source, icon: $icon, cover: $cover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search by title
#
# POST /v1/search
# operationId: post-search
# --filter shape: {property: "object", value: "page"|"data_source"}
export def "search post-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --body-sort: any
  --body-query: string
  --start-cursor: string # format: uuid
  --page-size: float
  --filter: record # shape: {property: "object", value: "page"|"data_source"}
]: any -> record<type: string, page_or_data_source: record, object: string, next_cursor: string, has_more: bool, results: list<any>, request_status: record<type: string, incomplete_reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/search")
  let body = {sort: $body_sort, query: $body_query, start_cursor: $start_cursor, page_size: $page_size, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a comment
#
# POST /v1/comments
# operationId: create-a-comment
# --attachments item shape: {file_upload_id: string, type?: string}
export def "comments create-a-comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --attachments: list # An array of files to attach to the comment. Maximum of 3 allowed. — item shape: {file_upload_id: string, type?: string}
  --display-name: any # Display name for the comment.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/comments")
  let body = {attachments: $attachments, display_name: $display_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List comments
#
# GET /v1/comments
# operationId: list-comments
export def "comments list-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --block-id: string
  --start-cursor: string
  --page-size: int
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, next_cursor: any, has_more: bool, results: table<object: string, id: string, parent: any, discussion_id: string, created_time: string, last_edited_time: string, created_by: record, rich_text: list, display_name: record, attachments: list>, type: string, comment: record, request_status: record<type: string, incomplete_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "block_id" $block_id "scalar") (serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/comments" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a comment
#
# GET /v1/comments/{comment_id}
# operationId: retrieve-comment
export def "comments retrieve-comment" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/comments/($comment_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a comment
#
# PATCH /v1/comments/{comment_id}
# operationId: update-a-comment
# --rich_text item shape: {annotations?: record}
export def "comments update-a-comment" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --rich-text: list # An array of rich text objects that represent the updated content of the comment. — item shape: {annotations?: record}
  --markdown: string # The updated content of the comment as a Markdown string. Comment Markdown supports inline formatting only (bold, italic, strikethrough, code, links), inline equations ($expression$), and mentions. Block-level Markdown such as fenced code blocks, headings, lists, tables, and blockquotes does not render as structured blocks in comments.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/comments/($comment_id)")
  let body = {rich_text: $rich_text, markdown: $markdown} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a comment
#
# DELETE /v1/comments/{comment_id}
# operationId: delete-a-comment
export def "comments delete-a-comment" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/comments/($comment_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a file upload
#
# POST /v1/file_uploads
# operationId: create-file
export def "file-uploads create-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --mode: string@mode-completer # How the file is being sent. Use `multi_part` for files larger than 20MB. Use `external_url` for files that are temporarily hosted publicly elsewhere. Default is `single_part`.
  --filename: string # Name of the file to be created. Required when `mode` is `multi_part`. Otherwise optional, and used to override the filename. Must include an extension, or have one inferred from the `content_type` parameter.
  --content-type: string # MIME type of the file to be created. Recommended when sending the file in multiple parts. Must match the content type of the file that's sent, and the extension of the `filename` parameter if any.
  --number-of-parts: int # When `mode` is `multi_part`, the number of parts you are uploading. This must match the number of parts as well as the final `part_number` you send.
  --external-url: string # When `mode` is `external_url`, provide the HTTPS URL of a publicly accessible file to import into your workspace.
]: any -> record<object: string, id: string, created_time: string, created_by: record<id: string, type: string>, last_edited_time: string, in_trash: bool, expiry_time: any, status: string, filename: any, content_type: any, content_length: any, upload_url: string, complete_url: string, file_import_result: record<imported_time: string>, number_of_parts: record<total: int, sent: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/file_uploads")
  let body = {mode: $mode, filename: $filename, content_type: $content_type, number_of_parts: $number_of_parts, external_url: $external_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List file uploads
#
# GET /v1/file_uploads
# operationId: list-file-uploads
export def "file-uploads list-file-uploads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer
  --start-cursor: string
  --page-size: int
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, next_cursor: any, has_more: bool, results: table<object: string, id: string, created_time: string, created_by: record, last_edited_time: string, in_trash: bool, expiry_time: any, status: string, filename: any, content_type: any, content_length: any, upload_url: string, complete_url: string, file_import_result: record, number_of_parts: record>, type: string, file_upload: record, request_status: record<type: string, incomplete_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/file_uploads" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a file
#
# POST /v1/file_uploads/{file_upload_id}/send
# operationId: upload-file
export def "file-uploads-send upload-file" [
  file_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  file: record # The raw binary file contents to upload.
  --part-number: string # When uploading files greater than 20MB in parts, this is the current part number. Must be an integer between 1 and 1,000.
]: any -> record<object: string, id: string, created_time: string, created_by: record<id: string, type: string>, last_edited_time: string, in_trash: bool, expiry_time: any, status: string, filename: any, content_type: any, content_length: any, upload_url: string, complete_url: string, file_import_result: record<imported_time: string>, number_of_parts: record<total: int, sent: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/file_uploads/($file_upload_id)/send")
  let body = {file: $file, part_number: $part_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Complete a multi-part file upload
#
# POST /v1/file_uploads/{file_upload_id}/complete
# operationId: complete-file-upload
export def "file-uploads-complete complete-file-upload" [
  file_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, id: string, created_time: string, created_by: record<id: string, type: string>, last_edited_time: string, in_trash: bool, expiry_time: any, status: string, filename: any, content_type: any, content_length: any, upload_url: string, complete_url: string, file_import_result: record<imported_time: string>, number_of_parts: record<total: int, sent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/file_uploads/($file_upload_id)/complete")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a file upload
#
# GET /v1/file_uploads/{file_upload_id}
# operationId: retrieve-file-upload
export def "file-uploads retrieve-file-upload" [
  file_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, id: string, created_time: string, created_by: record<id: string, type: string>, last_edited_time: string, in_trash: bool, expiry_time: any, status: string, filename: any, content_type: any, content_length: any, upload_url: string, complete_url: string, file_import_result: record<imported_time: string>, number_of_parts: record<total: int, sent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/file_uploads/($file_upload_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List custom emojis
#
# GET /v1/custom_emojis
# operationId: list-custom-emojis
export def "custom-emojis list-custom-emojis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-cursor: string
  --page-size: int
  --name: string
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, type: string, results: table<id: string, name: string, url: string>, has_more: bool, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/custom_emojis" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List views
#
# GET /v1/views
# operationId: list-views
export def "views list-views" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-id: string
  --data-source-id: string
  --start-cursor: string
  --page-size: int
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, next_cursor: any, has_more: bool, results: table<object: string, id: string>, type: string, view: record, request_status: record<type: string, incomplete_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "database_id" $database_id "scalar") (serialize-qp "data_source_id" $data_source_id "scalar") (serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/views" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a view
#
# POST /v1/views
# operationId: create-view
# --create_database shape: {parent: record, position?: record}
export def "views create-view" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  data_source_id: string
  name: string # The name of the view.
  type: string@type-completer # One of: `table`, `board`, `list`, `calendar`, `timeline`, `gallery`, `form`, `chart`, `map`, `dashboard`
  --database-id: string
  --view-id: string
  --filter: record # Filter for the view. Uses the same format as the data source query filter (property filters, timestamp filters, or compound and/or filters). Simple property filters appear in the view's filter bar in the Notion UI. Select, status, and multi_select filter operators accept a single string or an array of strings to filter by multiple values (e.g. { "does_not_equal": ["Done", "Archive"] }).
  --sorts: list
  --quick-filters: record # Quick filters to pin in the view's filter bar. Keys are property names or IDs. Values are filter conditions (same shape as a property filter but without the property field). Each quick filter appears as a clickable pill above the view, independent of the advanced filter.
  --create-database: record # shape: {parent: record, position?: record}
  --configuration: any # View configuration, discriminated by the type field.
  --position: any # Position of the new view in the database's view tab bar.
  --placement: any # Where to place the new widget in the dashboard. "new_row" creates a new row, "existing_row" adds to an existing row side-by-side with other widgets.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/views")
  let body = {data_source_id: $data_source_id, name: $name, type: $type, database_id: $database_id, view_id: $view_id, filter: $filter, sorts: $sorts, quick_filters: $quick_filters, create_database: $create_database, configuration: $configuration, position: $position, placement: $placement} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a view
#
# GET /v1/views/{view_id}
# operationId: retrieve-a-view
export def "views retrieve-a-view" [
  view_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/views/($view_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a view
#
# PATCH /v1/views/{view_id}
# operationId: update-a-view
export def "views update-a-view" [
  view_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --name: string # New name for the view.
  --filter: any # Filter to apply to the view. Uses the same format as the data source query filter. Pass null to clear the filter.
  --sorts: any # Property sorts to apply to the view. Only property-based sorts are supported. Pass null to clear the sorts.
  --quick-filters: any # Quick filters for the view's filter bar. Keys are property names or IDs. Set a key to a filter condition to add/update that quick filter. Set a key to null to remove it. Pass null for the entire field to clear all quick filters. Unmentioned quick filters are preserved.
  --configuration: any # View configuration, discriminated by the type field.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/views/($view_id)")
  let body = {name: $name, filter: $filter, sorts: $sorts, quick_filters: $quick_filters, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a view
#
# DELETE /v1/views/{view_id}
# operationId: delete-view
export def "views delete-view" [
  view_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, id: string, parent: record<type: string, database_id: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/views/($view_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a view query
#
# POST /v1/views/{view_id}/queries
# operationId: create-view-query
export def "views-queries create-view-query" [
  view_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --page-size: int # The number of results to return per page. Maximum: 100
]: any -> record<object: string, id: string, view_id: string, expires_at: string, total_count: float, results: table<object: string, id: string>, next_cursor: any, has_more: bool, request_status: record<type: string, incomplete_reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/views/($view_id)/queries")
  let body = {page_size: $page_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get view query results
#
# GET /v1/views/{view_id}/queries/{query_id}
# operationId: get-view-query-results
export def "views-queries get-view-query-results" [
  view_id: string
  query_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-cursor: string
  --page-size: int
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, next_cursor: any, has_more: bool, results: table<object: string, id: string>, type: string, page: record, request_status: record<type: string, incomplete_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_cursor" $start_cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/views/($view_id)/queries/($query_id)" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a view query
#
# DELETE /v1/views/{view_id}/queries/{query_id}
# operationId: delete-view-query
export def "views-queries delete-view-query" [
  view_id: string
  query_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/views/($view_id)/queries/($query_id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query meeting notes
#
# POST /v1/blocks/meeting_notes/query
# operationId: query-meeting-notes
# --filter shape: {operator: "and"|"or", filters?: list}
# --sort item shape: {property: "title"|"attendees"|"created_time"|"created_by"|"last_edited_time"|"last_edited_by", direction: "ascending"|"descending"}
export def "blocks-meeting-notes-query query-meeting-notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --filter: record # Optional filter for querying meeting notes. Supports combinator (and/or) and property filters on title, attendees, created_time, created_by, last_edited_time, last_edited_by. — shape: {operator: "and"|"or", filters?: list}
  --body-sort: list # Optional sort order for the results. Each entry specifies a property name and direction. — item shape: {property: "title"|"attendees"|"created_time"|"created_by"|"last_edited_time"|"last_edited_by", direction: "ascending"|"descending"}
  --limit: int # Maximum number of results to return. Defaults to 50.
]: any -> record<results: table<object: string, id: string, type: string, meeting_notes: record, created_time: string, last_edited_time: string, created_by: record, last_edited_by: record, has_children: bool, in_trash: bool>, has_more: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/blocks/meeting_notes/query")
  let body = {filter: $filter, sort: $body_sort, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exchange an authorization code for an access and refresh token
#
# POST /v1/oauth/token
# operationId: create-a-token
# --external_account shape: {key: string, name: string}
export def "oauth-token create-a-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --grant-type: string
  --code: string
  --redirect-uri: string
  --external-account: record # shape: {key: string, name: string}
  --refresh-token: string
]: any -> record<access_token: string, token_type: string, refresh_token: string, bot_id: string, workspace_icon: string, workspace_name: string, workspace_id: string, owner: any, duplicated_template_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/token")
  let body = {grant_type: $grant_type, code: $code, redirect_uri: $redirect_uri, external_account: $external_account, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke a token
#
# POST /v1/oauth/revoke
# operationId: revoke-token
export def "oauth-revoke revoke-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --body-token: string
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/revoke")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Introspect a token
#
# POST /v1/oauth/introspect
# operationId: introspect-token
export def "oauth-introspect introspect-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string@Notion-Version-completer # The [API version](/reference/versioning) to use for this request. The latest version is `2026-03-11`.
  --body-token: string
]: any -> record<active: bool, scope: string, iat: int, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/introspect")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
