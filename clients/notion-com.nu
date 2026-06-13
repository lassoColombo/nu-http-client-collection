# Auto-generated client for Notion API v1.0.0
# Source: https://api.apis.guru/v2/specs/notion.com/1.0.0/openapi.json
# Auth: --token flag or $env.NOTION_API_TOKEN

const BASE_URL = "https://api.notion.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOTION_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.notion.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "blocks delete" } } | get name | first)
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

# Delete a block
#
# DELETE /v1/blocks/{id}
# operationId: deleteABlock
export def "blocks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
]: nothing -> record<archived: bool, created_by: record<id: string, object: string>, created_time: string, has_children: bool, id: string, last_edited_by: record<id: string, object: string>, last_edited_time: string, object: string, paragraph: record<text: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a block
#
# GET /v1/blocks/{id}
# operationId: retrieveABlock
export def "blocks retrieveABlock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
]: nothing -> record<created_time: string, has_children: bool, id: string, last_edited_time: string, object: string, paragraph: record<text: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a block
#
# PATCH /v1/blocks/{id}
# operationId: updateABlock
# --paragraph shape: {rich_text?: list}
export def "blocks updateABlock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --paragraph: record # shape: {rich_text?: list}
]: any -> record<created_time: string, has_children: bool, id: string, last_edited_time: string, object: string, paragraph: record<text: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($id)")
  let body = {paragraph: $paragraph} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve block children
#
# GET /v1/blocks/{id}/children
# operationId: retrieveBlockChildren
export def "blocks-children retrieveBlockChildren" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # e.g. 100
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
]: nothing -> record<has_more: bool, next_cursor: any, object: string, results: table<created_time: string, has_children: bool, id: string, last_edited_time: string, object: string, paragraph: record, type: string, unsupported: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/blocks/($id)/children" $qp)
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Append block children
#
# PATCH /v1/blocks/{id}/children
# operationId: appendBlockChildren
# --children item shape: {heading_2?: record, object?: string, paragraph?: record, type?: string}
export def "blocks-children appendBlockChildren" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --children: list # e.g. [{heading_2: {text: [{text: {content: Lacinato kale}, type: text}]}, object: block, type: heading_2}, {object: block, paragraph: {rich_text: [{text: {content: Lacinato kale is a variety of kale with a long tradition in Italian cuisine, especially that of Tuscany. It is also known as Tuscan kale, Italian kale, dinosaur kale, kale, flat back kale, palm tree kale, or black Tuscan palm., link: {url: https://en.wikipedia.org/wiki/Lacinato_kale}}, type: text}]}, type: paragraph}] — item shape: {heading_2?: record, object?: string, paragraph?: record, type?: string}
]: any -> record<child_page: record<title: string>, created_time: string, has_children: bool, id: string, last_edited_time: string, object: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/blocks/($id)/children")
  let body = {children: $children} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve comments
#
# GET /v1/comments
# operationId: retrieveComments
export def "comments retrieveComments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --block-id: string # e.g. {{BLOCK_ID}}
  --page-size: string # e.g. 100
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --body: record
]: any -> record<comment: record, has_more: bool, next_cursor: any, object: string, results: table<created_by: record, created_time: string, discussion_id: string, id: string, last_edited_time: string, object: string, parent: record, rich_text: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "block_id" $block_id "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/comments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a database
#
# GET /v1/databases/{id}
# operationId: retrieveADatabase
export def "databases retrieveADatabase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
]: nothing -> record<archived: bool, cover: any, created_by: record<id: string, object: string>, created_time: string, icon: any, id: string, last_edited_by: record<id: string, object: string>, last_edited_time: string, object: string, parent: record<page_id: string, type: string>, properties: record<Author: record<id: string, multi_select: record, name: string, type: string>, Link: record<id: string, name: string, type: string, url: record>, Name: record<id: string, name: string, title: record, type: string>, Publisher: record<id: string, name: string, select: record, type: string>, Publishing_Release_Date: record<date: record, id: string, name: string, type: string>, Read: record<checkbox: record, id: string, name: string, type: string>, Score__5: record<id: string, name: string, select: record, type: string>, Status: record<id: string, name: string, select: record, type: string>, Summary: record<id: string, name: string, rich_text: record, type: string>, Type: record<id: string, name: string, select: record, type: string>>, title: table<annotations: record, href: any, plain_text: string, text: record, type: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/databases/($id)")
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a database
#
# PATCH /v1/databases/{id}
# operationId: updateADatabase
# --properties shape: {Wine Pairing?: record}
# --title item shape: {text?: record}
export def "databases updateADatabase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --properties: record # shape: {Wine Pairing?: record}
  --title: list # e.g. [{text: {content: Ever Better Reading List Title}}] — item shape: {text?: record}
]: any -> record<archived: bool, cover: any, created_by: record<id: string, object: string>, created_time: string, icon: any, id: string, last_edited_by: record<id: string, object: string>, last_edited_time: string, object: string, parent: record<page_id: string, type: string>, properties: record<Author: record<id: string, multi_select: record, name: string, type: string>, Link: record<id: string, name: string, type: string, url: record>, Name: record<id: string, name: string, title: record, type: string>, Publisher: record<id: string, name: string, select: record, type: string>, Publishing_Release_Date: record<date: record, id: string, name: string, type: string>, Read: record<checkbox: record, id: string, name: string, type: string>, Score__5: record<id: string, name: string, select: record, type: string>, Status: record<id: string, name: string, select: record, type: string>, Summary: record<id: string, name: string, rich_text: record, type: string>, Type: record<id: string, name: string, select: record, type: string>, Wine_Pairing: record<id: string, name: string, rich_text: record, type: string>>, title: table<annotations: record, href: any, plain_text: string, text: record, type: string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/databases/($id)")
  let body = {properties: $properties, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query a database
#
# POST /v1/databases/{id}/query
# operationId: queryADatabase
# --filter shape: {property?: string, select?: record}
export def "databases-query queryADatabase" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --filter: record # shape: {property?: string, select?: record}
]: any -> record<has_more: bool, next_cursor: any, object: string, results: table<archived: bool, cover: any, created_by: record, created_time: string, icon: any, id: string, last_edited_by: record, last_edited_time: string, object: string, parent: record, properties: record, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/databases/($id)/query")
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Page
#
# GET /v1/pages/{id}
# operationId: retrieveAPage
export def "pages retrieveAPage" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --param: string # e.g. 
]: nothing -> record<archived: bool, cover: any, created_by: record<id: string, object: string>, created_time: string, icon: record<emoji: string, type: string>, id: string, last_edited_by: record<id: string, object: string>, last_edited_time: string, object: string, parent: record<page_id: string, type: string>, properties: record<title: record<id: string, title: list, type: string>>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pages/($id)")
  let extra_headers = {"Notion-Version": $Notion_Version, "": $param} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Page properties 
#
# PATCH /v1/pages/{id}
# operationId: updatePageProperties
# --properties shape: {Status?: record}
export def "pages updatePageProperties" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --properties: record # shape: {Status?: record}
]: any -> record<archived: bool, created_time: string, id: string, last_edited_time: string, object: string, parent: record<database_id: string, type: string>, properties: record<Author: record<id: string, multi_select: list, type: string>, Link: record<id: string, type: string, url: string>, Name: record<id: string, title: list, type: string>, Publisher: record<id: string, select: record, type: string>, Publishing_Release_Date: record<date: record, id: string, type: string>, Read: record<checkbox: bool, id: string, type: string>, Score__5: record<id: string, select: record, type: string>, Status: record<id: string, select: record, type: string>, Summary: record<id: string, rich_text: list, type: string>, Type: record<id: string, select: record, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pages/($id)")
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Page Property Item
#
# GET /v1/pages/{page_id}/properties/{property_id}
# operationId: retrieveAPagePropertyItem
export def "pages-properties retrieveAPagePropertyItem" [
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
]: nothing -> record<object: string, select: record<color: string, id: string, name: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pages/($page_id)/properties/($property_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a user
#
# GET /v1/users/{id}
# operationId: retrieveAUser
export def "users retrieveAUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notion-Version: string # e.g. {{NOTION_VERSION}}
  --body: record
]: any -> record<avatar_url: any, id: string, name: string, object: string, person: record<email: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Notion-Version": $Notion_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
