# Auto-generated client for Figshare API v2.0.0
# Source: https://api.apis.guru/v2/specs/figshare.com/2.0.0/openapi.json
# Auth: --token flag or $env.FIGSHARE_API_TOKEN

const BASE_URL = "https://api.figshare.com/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FIGSHARE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.figshare.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["cites" "downloads" "modified_date" "published_date" "shares" "views"] }
def embargo-type-completer [] { ["article" "file"] }
def order-direction-completer [] { ["asc" "desc"] }
def order-completer-1 [] { ["cites" "modified_date" "published_date" "shares" "views"] }
def status-completer [] { ["approved" "closed" "pending" "rejected"] }
def order-completer-2 [] { ["modified_date" "published_date" "views"] }
def storage-completer [] { ["group" "individual"] }
def role-name-completer [] { ["collaborator" "viewer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Private Account information
#
# GET /account
# operationId: private_account
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: int, created_date: string, email: string, first_name: string, group_id: int, id: int, institution_id: int, institution_user_id: string, last_name: string, maximum_file_size: int, modified_date: string, pending_quota_request: bool, quota: int, used_quota: int, used_quota_private: int, used_quota_public: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Articles
#
# GET /account/articles
# operationId: private_articles_list
export def "account-articles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Article
#
# POST /account/articles
# operationId: private_article_create
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
# --timeline shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
export def "account-articles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # <b>One of:</b> <code>figure</code> <code>online resource</code> <code>preprint</code> <code>book</code> <code>conference contribution</code> <code>media</code> <code>dataset</code> <code>poster</code> <code>journal contribution</code> <code>presentation</code> <code>thesis</code> <code>software</code> (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: , e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --funding: string # Grant number or funding authority (default: )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --is-metadata-record: oneof<nothing, bool> # True if article has no files (e.g. true)
  --keywords: list # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --metadata-reason: string # Article metadata reason (e.g. hosted somewhere else)
  --references: list # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: )
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: )
  --tags: list # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  title: string # Title of article (e.g. Test article title)
]: any -> record<entity_id: int, location: string, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/articles")
  let body = {"authors": $authors, "categories": $categories, "categories_by_source_id": $categories_by_source_id, "custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "defined_type": $defined_type, "description": $description, "doi": $doi, "funding": $funding, "funding_list": $funding_list, "group_id": $group_id, "handle": $handle, "is_metadata_record": $is_metadata_record, "keywords": $keywords, "license": $license, "metadata_reason": $metadata_reason, "references": $references, "resource_doi": $resource_doi, "resource_title": $resource_title, "tags": $tags, "timeline": $timeline, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Account Article Report
#
# GET /account/articles/export
# operationId: account_article_report
export def "account-articles-export report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # A group ID to filter by (format: int64)
]: nothing -> table<account_id: int, created_date: string, download_url: string, group_id: int, id: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/articles/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate a new Report
#
# POST /account/articles/export
# operationId: account_article_report_generate
export def "account-articles-export generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: int, created_date: string, download_url: string, group_id: int, id: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/articles/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Articles search
#
# POST /account/articles/search
# operationId: private_articles_search
export def "account-articles-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-id: string # only return collections with this resource_id (e.g. 1407024)
  --doi: string # Only return articles with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return articles with this handle (e.g. 111084/m9.figshare.14074)
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64, e.g. 1)
  --order: string@order-completer # The field by which to order (default: created_date, e.g. published_date)
  --project-id: int # Only return articles in this project (format: int64, e.g. 1)
  --resource-doi: string # Only return articles with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
]: any -> table<project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/articles/search")
  let body = {"resource_id": $resource_id, "doi": $doi, "handle": $handle, "item_type": $item_type, "order": $order, "project_id": $project_id, "resource_doi": $resource_doi} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete article
#
# DELETE /account/articles/{article_id}
# operationId: private_article_delete
export def "account-articles delete" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Article details
#
# GET /account/articles/{article_id}
# operationId: private_article_details
export def "account-articles details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: int, group_resource_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update article
#
# PUT /account/articles/{article_id}
# operationId: private_article_update
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
# --timeline shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
export def "account-articles update" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # <b>One of:</b> <code>figure</code> <code>online resource</code> <code>preprint</code> <code>book</code> <code>conference contribution</code> <code>media</code> <code>dataset</code> <code>poster</code> <code>journal contribution</code> <code>presentation</code> <code>thesis</code> <code>software</code> (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: , e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --funding: string # Grant number or funding authority (default: )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --is-metadata-record: oneof<nothing, bool> # True if article has no files (e.g. true)
  --keywords: list # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --metadata-reason: string # Article metadata reason (e.g. hosted somewhere else)
  --references: list # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: )
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: )
  --tags: list # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  --title: string # Title of article (e.g. Test article title)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}"))
  let body = {"authors": $authors, "categories": $categories, "categories_by_source_id": $categories_by_source_id, "custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "defined_type": $defined_type, "description": $description, "doi": $doi, "funding": $funding, "funding_list": $funding_list, "group_id": $group_id, "handle": $handle, "is_metadata_record": $is_metadata_record, "keywords": $keywords, "license": $license, "metadata_reason": $metadata_reason, "references": $references, "resource_doi": $resource_doi, "resource_title": $resource_title, "tags": $tags, "timeline": $timeline, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List article authors
#
# GET /account/articles/{article_id}/authors
# operationId: private_article_authors_list
export def "account-articles-authors list" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/authors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add article authors
#
# POST /account/articles/{article_id}/authors
# operationId: private_article_authors_add
export def "account-articles-authors add" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/authors"))
  let body = {"authors": $authors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace article authors
#
# PUT /account/articles/{article_id}/authors
# operationId: private_article_authors_replace
export def "account-articles-authors replace" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/authors"))
  let body = {"authors": $authors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete article author
#
# DELETE /account/articles/{article_id}/authors/{author_id}
# operationId: private_article_author_delete
export def "account-articles-authors delete" [
  article_id: int
  author_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, author_id: $author_id} | format pattern "/account/articles/{article_id}/authors/{author_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List article categories
#
# GET /account/articles/{article_id}/categories
# operationId: private_article_categories_list
export def "account-articles-categories list" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add article categories
#
# POST /account/articles/{article_id}/categories
# operationId: private_article_categories_add
export def "account-articles-categories add" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list # List of category ids (e.g. [1, 10, 11])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/categories"))
  let body = {"categories": $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace article categories
#
# PUT /account/articles/{article_id}/categories
# operationId: private_article_categories_replace
export def "account-articles-categories replace" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list # List of category ids (e.g. [1, 10, 11])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/categories"))
  let body = {"categories": $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete article category
#
# DELETE /account/articles/{article_id}/categories/{category_id}
# operationId: private_article_category_delete
export def "account-articles-categories delete" [
  article_id: int
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, category_id: $category_id} | format pattern "/account/articles/{article_id}/categories/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete article confidentiality
#
# DELETE /account/articles/{article_id}/confidentiality
# operationId: private_article_confidentiality_delete
export def "account-articles-confidentiality delete" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/confidentiality"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Article confidentiality details
#
# GET /account/articles/{article_id}/confidentiality
# operationId: private_article_confidentiality_details
export def "account-articles-confidentiality details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_confidential: bool, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/confidentiality"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update article confidentiality
#
# PUT /account/articles/{article_id}/confidentiality
# operationId: private_article_confidentiality_update
export def "account-articles-confidentiality update" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # Reason for confidentiality
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/confidentiality"))
  let body = {"reason": $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Article Embargo
#
# DELETE /account/articles/{article_id}/embargo
# operationId: private_article_embargo_delete
export def "account-articles-embargo delete" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/embargo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Article Embargo Details
#
# GET /account/articles/{article_id}/embargo
# operationId: private_article_embargo_details
export def "account-articles-embargo details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<embargo_date: string, embargo_options: list<record>, embargo_reason: string, embargo_title: string, embargo_type: string, is_embargoed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/embargo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Article Embargo
#
# PUT /account/articles/{article_id}/embargo
# operationId: private_article_embargo_update
export def "account-articles-embargo update" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  embargo_date: string # Date when the embargo expires and the article gets published, '0' value will set up permanent embargo (e.g. 2018-05-22T04:04:04)
  --embargo-options: list # List of embargo permissions to be associated with the article. The list must contain `id` and can also contain `group_ids`(a field that only applies to 'logged_in' permissions). The new list replaces old options in the database, and an empty list removes all permissions for this article. Administration permission has to be set up alone but logged in and IP range permissions can be set up together. (e.g. [{id: 1321}, {id: 3345}, {group_ids: [4332, 5433, 678], id: 54621}])
  --embargo-reason: string # Reason for setting embargo (e.g. )
  --embargo-title: string # Title for embargo (e.g. File(s) under embargo)
  embargo_type: string@embargo-type-completer # Embargo can be enabled at the article or the file level. Possible values: article, file (e.g. file)
  --is-embargoed: oneof<nothing, bool> # Embargo status (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/embargo"))
  let body = {"embargo_date": $embargo_date, "embargo_options": $embargo_options, "embargo_reason": $embargo_reason, "embargo_title": $embargo_title, "embargo_type": $embargo_type, "is_embargoed": $is_embargoed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List article files
#
# GET /account/articles/{article_id}/files
# operationId: private_article_files_list
export def "account-articles-files list" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate Upload
#
# POST /account/articles/{article_id}/files
# operationId: private_article_upload_initiate
export def "account-articles-files initiate" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --link: string # Url for an existing file that will not be uploaded to Figshare (e.g. http://figshare.com/file.txt)
  --md5: string # MD5 sum pre-computed on client side. (e.g. 6c16e6e7d7587bd078e5117dda01d565)
  --name: string # File name including the extension; can be omitted only for linked files. (e.g. test.py)
  --size: int # File size in bytes; can be omitted only for linked files. (format: int64, e.g. 70)
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/files"))
  let body = {"link": $link, "md5": $md5, "name": $name, "size": $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# File Delete
#
# DELETE /account/articles/{article_id}/files/{file_id}
# operationId: private_article_file_delete
export def "account-articles-files delete" [
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, file_id: $file_id} | format pattern "/account/articles/{article_id}/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single File
#
# GET /account/articles/{article_id}/files/{file_id}
# operationId: private_article_file
export def "account-articles-files file" [
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, file_id: $file_id} | format pattern "/account/articles/{article_id}/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete Upload
#
# POST /account/articles/{article_id}/files/{file_id}
# operationId: private_article_upload_complete
export def "account-articles-files complete" [
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, file_id: $file_id} | format pattern "/account/articles/{article_id}/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List private links
#
# GET /account/articles/{article_id}/private_links
# operationId: private_article_private_link
export def "account-articles-private-links link" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<expires_date: string, html_location: string, id: string, is_active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/private_links"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create private link
#
# POST /account/articles/{article_id}/private_links
# operationId: private_article_private_link_create
export def "account-articles-private-links create" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> record<html_location: string, location: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/private_links"))
  let body = {"expires_date": $expires_date, "read_only": $read_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable private link
#
# DELETE /account/articles/{article_id}/private_links/{link_id}
# operationId: private_article_private_link_delete
export def "account-articles-private-links delete" [
  article_id: int
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, link_id: $link_id} | format pattern "/account/articles/{article_id}/private_links/{link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update private link
#
# PUT /account/articles/{article_id}/private_links/{link_id}
# operationId: private_article_private_link_update
export def "account-articles-private-links update" [
  article_id: int
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, link_id: $link_id} | format pattern "/account/articles/{article_id}/private_links/{link_id}"))
  let body = {"expires_date": $expires_date, "read_only": $read_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Article Publish
#
# POST /account/articles/{article_id}/publish
# operationId: private_article_publish
export def "account-articles-publish publish" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<location: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/publish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Article Reserve DOI
#
# POST /account/articles/{article_id}/reserve_doi
# operationId: private_article_reserve_doi
export def "account-articles-reserve-doi doi" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<doi: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/reserve_doi"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Article Reserve Handle
#
# POST /account/articles/{article_id}/reserve_handle
# operationId: private_article_reserve_handle
export def "account-articles-reserve-handle handle" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<handle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/reserve_handle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Article Resource
#
# POST /account/articles/{article_id}/resource
# operationId: private_article_resource
export def "account-articles-resource resource" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doi: string # DOI of resource item (default: )
  --id: string # ID of resource item (default: , e.g. aaaa23512)
  --link: string # Link of resource item (default: , e.g. https://docs.figshare.com)
  --status: string # Status of resource item (default: , e.g. frozen)
  --title: string # Title of resource item (default: , e.g. Test title)
  --version: int # Version of resource item (format: int64, default: 0, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/account/articles/{article_id}/resource"))
  let body = {"doi": $doi, "id": $id, "link": $link, "status": $status, "title": $title, "version": $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update article version
#
# PUT /account/articles/{article_id}/versions/{version_id}/
# operationId: article_version_update
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
# --timeline shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
export def "account-articles-versions update" [
  article_id: int
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # <b>One of:</b> <code>figure</code> <code>online resource</code> <code>preprint</code> <code>book</code> <code>conference contribution</code> <code>media</code> <code>dataset</code> <code>poster</code> <code>journal contribution</code> <code>presentation</code> <code>thesis</code> <code>software</code> (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: , e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --funding: string # Grant number or funding authority (default: )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --is-metadata-record: oneof<nothing, bool> # True if article has no files (e.g. true)
  --keywords: list # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --metadata-reason: string # Article metadata reason (e.g. hosted somewhere else)
  --references: list # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: )
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: )
  --tags: list # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  --title: string # Title of article (e.g. Test article title)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, version_id: $version_id} | format pattern "/account/articles/{article_id}/versions/{version_id}/"))
  let body = {"authors": $authors, "categories": $categories, "categories_by_source_id": $categories_by_source_id, "custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "defined_type": $defined_type, "description": $description, "doi": $doi, "funding": $funding, "funding_list": $funding_list, "group_id": $group_id, "handle": $handle, "is_metadata_record": $is_metadata_record, "keywords": $keywords, "license": $license, "metadata_reason": $metadata_reason, "references": $references, "resource_doi": $resource_doi, "resource_title": $resource_title, "tags": $tags, "timeline": $timeline, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update article version thumbnail
#
# PUT /account/articles/{article_id}/versions/{version_id}/update_thumb
# operationId: article_version_update_thumb
export def "account-articles-versions-update-thumb thumb" [
  article_id: int
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File ID (format: int64, e.g. 123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, version_id: $version_id} | format pattern "/account/articles/{article_id}/versions/{version_id}/update_thumb"))
  let body = {"file_id": $file_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Authors
#
# POST /account/authors/search
# operationId: private_authors_search
export def "account-authors-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Return only authors in this group or subgroups of the group (format: int64)
  --institution-id: int # Return only authors associated to this institution (format: int64, e.g. 1)
  --is-active: oneof<nothing, bool> # Return only active authors if True
  --is-public: oneof<nothing, bool> # Return only authors that have published items if True
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --orcid: string # Orcid of author
  --order: string@order-completer # The field by which to order. Default varies by endpoint/resource. (default: published_date, e.g. published_date)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --search-for: string # Search term (e.g. figshare)
]: any -> table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/authors/search")
  let body = {"group_id": $group_id, "institution_id": $institution_id, "is_active": $is_active, "is_public": $is_public, "limit": $limit, "offset": $offset, "orcid": $orcid, "order": $order, "order_direction": $order_direction, "page": $page, "page_size": $page_size, "search_for": $search_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Author details
#
# GET /account/authors/{author_id}
# operationId: private_author_details
export def "account-authors details" [
  author_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<first_name: string, group_id: int, institution_id: int, is_public: int, job_title: string, last_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({author_id: $author_id} | format pattern "/account/authors/{author_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Account Categories
#
# GET /account/categories
# operationId: private_categories_list
export def "account-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Collections List
#
# GET /account/collections
# operationId: private_collections_list
export def "account-collections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-1 # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
]: nothing -> table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_direction" $order_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create collection
#
# POST /account/collections
# operationId: private_collection_create
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
# --timeline shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
export def "account-collections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --articles: list # List of articles to be associated with the collection (e.g. [2000001, 2000005])
  --authors: list # List of authors to be associated with the collection. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 20005}])
  --categories: list # List of category ids to be associated with the collection(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list # List of category source ids to be associated with the collection, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the collection (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # The collection description. In a publisher case, usually this is the remote collection description (default: , e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --funding: string # Grant number or funding authority (default: )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --keywords: list # List of tags to be associated with the collection. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --references: list # List of links to be associated with the collection (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: )
  --resource-id: string # Not applicable to regular users. In a publisher case, this is the publisher article id
  --resource-link: string # Not applicable to regular users. In a publisher case, this is the publisher article link
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: )
  --resource-version: int # Not applicable to regular users. In a publisher case, this is the publisher article version
  --tags: list # List of tags to be associated with the collection. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  title: string # Title of collection (e.g. Test collection title)
]: any -> record<entity_id: int, location: string, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/collections")
  let body = {"articles": $articles, "authors": $authors, "categories": $categories, "categories_by_source_id": $categories_by_source_id, "custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "description": $description, "doi": $doi, "funding": $funding, "funding_list": $funding_list, "group_id": $group_id, "handle": $handle, "keywords": $keywords, "references": $references, "resource_doi": $resource_doi, "resource_id": $resource_id, "resource_link": $resource_link, "resource_title": $resource_title, "resource_version": $resource_version, "tags": $tags, "timeline": $timeline, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Collections Search
#
# POST /account/collections/search
# operationId: private_collections_search
export def "account-collections-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-id: string # only return collections with this resource_id (e.g. 1407024)
  --doi: string # Only return collections with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return collections with this handle (e.g. 10084/figshare.1407024)
  --order: string@order-completer-1 # The field by which to order. (default: created_date, e.g. published_date)
  --resource-doi: string # Only return collections with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
]: any -> table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/collections/search")
  let body = {"resource_id": $resource_id, "doi": $doi, "handle": $handle, "order": $order, "resource_doi": $resource_doi} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete collection
#
# DELETE /account/collections/{collection_id}
# operationId: private_collection_delete
export def "account-collections delete" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collection details
#
# GET /account/collections/{collection_id}
# operationId: private_collection_details
export def "account-collections details" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: int, articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update collection
#
# PUT /account/collections/{collection_id}
# operationId: private_collection_update
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
# --timeline shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
export def "account-collections update" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --articles: list # List of articles to be associated with the collection (e.g. [2000001, 2000005])
  --authors: list # List of authors to be associated with the collection. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 20005}])
  --categories: list # List of category ids to be associated with the collection (e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the collection (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # The collection description. In a publisher case, usually this is the remote collection description (default: , e.g. Test description of collection)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --funding: string # Grant number or funding authority (default: )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --keywords: list # List of tags to be associated with the collection. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --references: list # List of links to be associated with the collection (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: )
  --resource-id: string # Not applicable to regular users. In a publisher case, this is the publisher article id
  --resource-link: string # Not applicable to regular users. In a publisher case, this is the publisher article link
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: )
  --resource-version: int # Not applicable to regular users. In a publisher case, this is the publisher article version
  --tags: list # List of tags to be associated with the collection. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  --title: string # Title of collection (e.g. Test collection title)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}"))
  let body = {"articles": $articles, "authors": $authors, "categories": $categories, "categories_by_source_id": $categories_by_source_id, "custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "description": $description, "doi": $doi, "funding": $funding, "funding_list": $funding_list, "group_id": $group_id, "handle": $handle, "keywords": $keywords, "references": $references, "resource_doi": $resource_doi, "resource_id": $resource_id, "resource_link": $resource_link, "resource_title": $resource_title, "resource_version": $resource_version, "tags": $tags, "timeline": $timeline, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List collection articles
#
# GET /account/collections/{collection_id}/articles
# operationId: private_collection_articles_list
export def "account-collections-articles list" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/articles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add collection articles
#
# POST /account/collections/{collection_id}/articles
# operationId: private_collection_articles_add
export def "account-collections-articles add" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  articles: list # List of article ids (e.g. [2000003, 2000004])
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/articles"))
  let body = {"articles": $articles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace collection articles
#
# PUT /account/collections/{collection_id}/articles
# operationId: private_collection_articles_replace
export def "account-collections-articles replace" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  articles: list # List of article ids (e.g. [2000003, 2000004])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/articles"))
  let body = {"articles": $articles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete collection article
#
# DELETE /account/collections/{collection_id}/articles/{article_id}
# operationId: private_collection_article_delete
export def "account-collections-articles delete" [
  collection_id: int
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id, article_id: $article_id} | format pattern "/account/collections/{collection_id}/articles/{article_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List collection authors
#
# GET /account/collections/{collection_id}/authors
# operationId: private_collection_authors_list
export def "account-collections-authors list" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/authors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add collection authors
#
# POST /account/collections/{collection_id}/authors
# operationId: private_collection_authors_add
export def "account-collections-authors add" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/authors"))
  let body = {"authors": $authors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace collection authors
#
# PUT /account/collections/{collection_id}/authors
# operationId: private_collection_authors_replace
export def "account-collections-authors replace" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (e.g. [{id: 12121}, {id: 34345}, {name: John Doe}])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/authors"))
  let body = {"authors": $authors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete collection author
#
# DELETE /account/collections/{collection_id}/authors/{author_id}
# operationId: private_collection_author_delete
export def "account-collections-authors delete" [
  collection_id: int
  author_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id, author_id: $author_id} | format pattern "/account/collections/{collection_id}/authors/{author_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List collection categories
#
# GET /account/collections/{collection_id}/categories
# operationId: private_collection_categories_list
export def "account-collections-categories list" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add collection categories
#
# POST /account/collections/{collection_id}/categories
# operationId: private_collection_categories_add
export def "account-collections-categories add" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list # List of category ids (e.g. [1, 10, 11])
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/categories"))
  let body = {"categories": $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace collection categories
#
# PUT /account/collections/{collection_id}/categories
# operationId: private_collection_categories_replace
export def "account-collections-categories replace" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list # List of category ids (e.g. [1, 10, 11])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/categories"))
  let body = {"categories": $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete collection category
#
# DELETE /account/collections/{collection_id}/categories/{category_id}
# operationId: private_collection_category_delete
export def "account-collections-categories delete" [
  collection_id: int
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id, category_id: $category_id} | format pattern "/account/collections/{collection_id}/categories/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List collection private links
#
# GET /account/collections/{collection_id}/private_links
# operationId: private_collection_private_links_list
export def "account-collections-private-links list" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<expires_date: string, html_location: string, id: string, is_active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/private_links"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create collection private link
#
# POST /account/collections/{collection_id}/private_links
# operationId: private_collection_private_link_create
export def "account-collections-private-links create" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> record<html_location: string, location: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/private_links"))
  let body = {"expires_date": $expires_date, "read_only": $read_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable private link
#
# DELETE /account/collections/{collection_id}/private_links/{link_id}
# operationId: private_collection_private_link_delete
export def "account-collections-private-links delete" [
  collection_id: int
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id, link_id: $link_id} | format pattern "/account/collections/{collection_id}/private_links/{link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update collection private link
#
# PUT /account/collections/{collection_id}/private_links/{link_id}
# operationId: private_collection_private_link_update
export def "account-collections-private-links update" [
  collection_id: int
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-date: string # Date when this private link should expire - optional. By default private links expire in 365 days. (e.g. 2018-02-22 22:22:22)
  --read-only: oneof<nothing, bool> # Optional, default true. Set to false to give private link users editing rights for this collection. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id, link_id: $link_id} | format pattern "/account/collections/{collection_id}/private_links/{link_id}"))
  let body = {"expires_date": $expires_date, "read_only": $read_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Collection Publish
#
# POST /account/collections/{collection_id}/publish
# operationId: private_collection_publish
export def "account-collections-publish publish" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<location: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/publish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Collection Reserve DOI
#
# POST /account/collections/{collection_id}/reserve_doi
# operationId: private_collection_reserve_doi
export def "account-collections-reserve-doi doi" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<doi: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/reserve_doi"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Collection Reserve Handle
#
# POST /account/collections/{collection_id}/reserve_handle
# operationId: private_collection_reserve_handle
export def "account-collections-reserve-handle handle" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<handle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/reserve_handle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Collection Resource
#
# POST /account/collections/{collection_id}/resource
# operationId: private_collection_resource
export def "account-collections-resource resource" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doi: string # DOI of resource item (default: )
  --id: string # ID of resource item (default: , e.g. aaaa23512)
  --link: string # Link of resource item (default: , e.g. https://docs.figshare.com)
  --status: string # Status of resource item (default: , e.g. frozen)
  --title: string # Title of resource item (default: , e.g. Test title)
  --version: int # Version of resource item (format: int64, default: 0, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/account/collections/{collection_id}/resource"))
  let body = {"doi": $doi, "id": $id, "link": $link, "status": $status, "title": $title, "version": $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Funding
#
# POST /account/funding/search
# operationId: private_funding_search
export def "account-funding-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-for: string # Search term
]: any -> table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/funding/search")
  let body = {"search_for": $search_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Account Institutions
#
# GET /account/institution
# operationId: private_institution_details
export def "account-institution details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/institution")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Account Institution Accounts
#
# GET /account/institution/accounts
# operationId: private_institution_accounts_list
export def "account-institution-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --is-active: int # Filter by active status (format: int64)
  --institution-user-id: string # Filter by institution_user_id
  --email: string # Filter by email
  --id-lte: int # Retrieve accounts with an ID lower or equal to the specified value (format: int64)
  --id-gte: int # Retrieve accounts with an ID greater or equal to the specified value (format: int64)
]: nothing -> table<active: int, email: string, first_name: string, id: int, institution_id: int, institution_user_id: string, last_name: string, orcid_id: string, quota: int, used_quota: int, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "institution_user_id" $institution_user_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "id_lte" $id_lte "scalar") (serialize-qp "id_gte" $id_gte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/institution/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Institution Account
#
# POST /account/institution/accounts
# operationId: private_institution_accounts_create
export def "account-institution-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email of account (e.g. johndoe@example.com)
  first_name: string # First Name (default: , e.g. John)
  --group-id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --institution-user-id: string # Institution user id (default: , e.g. johndoe)
  --is-active: oneof<nothing, bool> # Is account active
  --last-name: string # Last Name (default: , e.g. Doe)
  --quota: int # Account quota (format: int64, e.g. 1000)
  --symplectic-user-id: string # Symplectic user id (default: , e.g. johndoe)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/institution/accounts")
  let body = {"email": $email, "first_name": $first_name, "group_id": $group_id, "institution_user_id": $institution_user_id, "is_active": $is_active, "last_name": $last_name, "quota": $quota, "symplectic_user_id": $symplectic_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Account Institution Accounts Search
#
# POST /account/institution/accounts/search
# operationId: private_institution_accounts_search
export def "account-institution-accounts-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # filter by email (e.g. alan@institution.com)
  --institution-user-id: string # filter by institution_user_id (e.g. alan)
  --is-active: int # Filter by active status (format: int64)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --search-for: string # Search term (e.g. figshare)
]: any -> table<active: int, email: string, first_name: string, id: int, institution_id: int, institution_user_id: string, last_name: string, orcid_id: string, quota: int, used_quota: int, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/institution/accounts/search")
  let body = {"email": $email, "institution_user_id": $institution_user_id, "is_active": $is_active, "limit": $limit, "offset": $offset, "page": $page, "page_size": $page_size, "search_for": $search_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Institution Account
#
# PUT /account/institution/accounts/{account_id}
# operationId: private_institution_accounts_update
export def "account-institution-accounts update" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group_id: int # Not applicable to regular users. This field is reserved to institutions/publishers with access to assign to specific groups (format: int64)
  --is-active: oneof<nothing, bool> # Is account active
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/account/institution/accounts/{account_id}"))
  let body = {"group_id": $group_id, "is_active": $is_active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Institution Articles
#
# GET /account/institution/articles
# operationId: private_institution_articles
export def "account-institution-articles articles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --status: int # only return collections with this status (format: int64)
  --resource-doi: string # only return collections with this resource_doi
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64)
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "published_since" $published_since "scalar") (serialize-qp "modified_since" $modified_since "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "resource_doi" $resource_doi "scalar") (serialize-qp "item_type" $item_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/institution/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private account institution group custom fields
#
# GET /account/institution/custom_fields
# operationId: custom_fields_list
export def "account-institution-custom-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Group_id (format: int64)
]: nothing -> table<field_type: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/institution/custom_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Custom fields values files upload
#
# POST /account/institution/custom_fields/{custom_field_id}/items/upload
# operationId: custom_fields_upload
export def "account-institution-custom-fields-items-upload upload" [
  custom_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-file: string # CSV file to be uploaded (format: binary)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({custom_field_id: $custom_field_id} | format pattern "/account/institution/custom_fields/{custom_field_id}/items/upload"))
  let body = {"external_file": $external_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Private Account Institution embargo options
#
# GET /account/institution/embargo_options
# operationId: private_institution_embargo_options_details
export def "account-institution-embargo-options details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, ip_name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/institution/embargo_options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Account Institution Groups
#
# GET /account/institution/groups
# operationId: private_institution_groups_list
export def "account-institution-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<association_criteria: string, id: int, name: string, parent_id: int, resource_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/institution/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Account Institution Group Embargo Options
#
# GET /account/institution/groups/{group_id}/embargo_options
# operationId: private_group_embargo_options_details
export def "account-institution-groups-embargo-options details" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, ip_name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/account/institution/groups/{group_id}/embargo_options"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Institution Curation Review
#
# GET /account/institution/review/{curation_id}
# operationId: account_institution_curation
export def "account-institution-review curation" [
  curation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<item: record<authors: list<record>, custom_fields: list<record>, embargo_options: list<record>, figshare_url: string, files: list<record>, resource_doi: string, resource_title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({curation_id: $curation_id} | format pattern "/account/institution/review/{curation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Institution Curation Review Comments
#
# GET /account/institution/review/{curation_id}/comments
# operationId: account_institution_curation_comments
export def "account-institution-review-comments comments" [
  curation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> record<account_id: int, id: int, text: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({curation_id: $curation_id} | format pattern "/account/institution/review/{curation_id}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST Institution Curation Review Comment
#
# POST /account/institution/review/{curation_id}/comments
export def "account-institution-review-comments post" [
  curation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # The contents/value of the comment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({curation_id: $curation_id} | format pattern "/account/institution/review/{curation_id}/comments"))
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Institution Curation Reviews
#
# GET /account/institution/reviews
# operationId: account_institution_curations
export def "account-institution-reviews curations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Filter by the group ID (format: int64)
  --article-id: int # Retrieve the reviews for this article (format: int64)
  --status: string@status-completer # Filter by the status of the review
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> record<account_id: int, article_id: int, assigned_to: int, comments_count: int, created_date: string, group_id: int, id: int, modified_date: string, review_date: string, status: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_id" $group_id "scalar") (serialize-qp "article_id" $article_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/institution/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Account Institution Roles
#
# GET /account/institution/roles
# operationId: private_institution_roles_list
export def "account-institution-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, description: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/institution/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Institution Account Group Roles
#
# GET /account/institution/roles/{account_id}
# operationId: private_institution_account_group_roles
export def "account-institution-roles roles" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/account/institution/roles/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Institution Account Group Roles
#
# POST /account/institution/roles/{account_id}
# operationId: private_institution_account_group_roles_create
export def "account-institution-roles create" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/account/institution/roles/{account_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Institution Account Group Role
#
# DELETE /account/institution/roles/{account_id}/{group_id}/{role_id}
# operationId: private_institution_account_group_role_delete
export def "account-institution-roles delete" [
  account_id: int
  group_id: int
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id, group_id: $group_id, role_id: $role_id} | format pattern "/account/institution/roles/{account_id}/{group_id}/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Account Institution User
#
# GET /account/institution/users/{account_id}
# operationId: private_account_institution_user
export def "account-institution-users user" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<first_name: string, id: int, is_active: bool, is_public: bool, job_title: string, last_name: string, name: string, orcid_id: string, url_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/account/institution/users/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Account Licenses
#
# GET /account/licenses
# operationId: private_licenses_list
export def "account-licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, url: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/licenses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Projects
#
# GET /account/projects
# operationId: private_projects_list
export def "account-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-2 # The field by which to order. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --storage: string@storage-completer # only return collections from this institution
  --roles: string # Any combination of owner, collaborator, viewer separated by comma. Examples: "owner" or "owner,collaborator".
]: nothing -> table<role: string, storage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "storage" $storage "scalar") (serialize-qp "roles" $roles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project
#
# POST /account/projects
# operationId: private_project_create
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
export def "account-projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # List of key, values pairs to be associated with the project (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # Project description (e.g. project description)
  --funding: string # Grant number or organization(s) that funded this project. Up to 2000 characters permitted. (e.g. )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --group-id: int # Only if project type is group. (format: int64, e.g. 0)
  title: string # The title for this project - mandatory. 3 - 1000 characters. (e.g. project title)
]: any -> record<entity_id: int, location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/projects")
  let body = {"custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "description": $description, "funding": $funding, "funding_list": $funding_list, "group_id": $group_id, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Projects search
#
# POST /account/projects/search
# operationId: private_projects_search
export def "account-projects-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer-2 # The field by which to order. (default: published_date, e.g. published_date)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> table<role: string, storage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/projects/search")
  let body = {"order": $order, "group": $group, "institution": $institution, "limit": $limit, "modified_since": $modified_since, "offset": $offset, "order_direction": $order_direction, "page": $page, "page_size": $page_size, "published_since": $published_since, "search_for": $search_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete project
#
# DELETE /account/projects/{project_id}
# operationId: private_project_delete
export def "account-projects delete" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project details
#
# GET /account/projects/{project_id}
# operationId: private_project_details
export def "account-projects details" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: int, collaborators: table<name: string, role_name: string, user_id: int>, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, figshare_url: string, funding: string, funding_list: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, modified_date: string, quota: int, used_quota: int, used_quota_private: int, used_quota_public: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project
#
# PUT /account/projects/{project_id}
# operationId: private_project_update
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
export def "account-projects update" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # List of key, values pairs to be associated with the project (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --description: string # Project description (e.g. project description)
  --funding: string # Grant number or organization(s) that funded this project. Up to 2000 characters permitted. (e.g. )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --title: string # The title for this project - mandatory. 3 - 1000 characters. (e.g. project title)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}"))
  let body = {"custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "description": $description, "funding": $funding, "funding_list": $funding_list, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List project articles
#
# GET /account/projects/{project_id}/articles
# operationId: private_project_articles_list
export def "account-projects-articles list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/articles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project article
#
# POST /account/projects/{project_id}/articles
# operationId: private_project_articles_create
# --custom_fields_list item shape: {name: string, value: any}
# --funding_list item shape: {id?: int, title?: string}
# --timeline shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
export def "account-projects-articles create" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --authors: list # List of authors to be associated with the article. The list can contain the following fields: id, name, first_name, last_name, email, orcid_id. If an id is supplied, it will take priority and everything else will be ignored. No more than 10 authors. For adding more authors use the specific authors endpoint. (default: [], e.g. [{name: John Doe}, {id: 1000008}])
  --categories: list # List of category ids to be associated with the article(e.g [1, 23, 33, 66]) (default: [], e.g. [1, 10, 11])
  --categories-by-source-id: list # List of category source ids to be associated with the article, supersedes the categories property (default: [], e.g. [300204, 400207])
  --custom-fields: record # List of key, values pairs to be associated with the article (e.g. {defined_key: value for it})
  --custom-fields-list: list # List of custom fields values, supersedes custom_fields parameter — item shape: {name: string, value: any}
  --defined-type: string # <b>One of:</b> <code>figure</code> <code>online resource</code> <code>preprint</code> <code>book</code> <code>conference contribution</code> <code>media</code> <code>dataset</code> <code>poster</code> <code>journal contribution</code> <code>presentation</code> <code>thesis</code> <code>software</code> (e.g. media)
  --description: string # The article description. In a publisher case, usually this is the remote article description (default: , e.g. Test description of article)
  --doi: string # Not applicable for regular users. In an institutional case, make sure your group supports setting DOIs. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --funding: string # Grant number or funding authority (default: )
  --funding-list: list # Funding creation / update items — item shape: {id?: int, title?: string}
  --handle: string # Not applicable for regular users. In an institutional case, make sure your group supports setting Handles. This setting is applied by figshare via opening a ticket through our support/helpdesk system. (default: )
  --keywords: list # List of tags to be associated with the article. Tags can be used instead (default: [], e.g. [tag1, tag2])
  --license: int # License id for this article. (format: int64, default: 0, e.g. 1)
  --references: list # List of links to be associated with the article (e.g ["http://link1", "http://link2", "http://link3"]) (default: [], e.g. [http://figshare.com, http://api.figshare.com])
  --resource-doi: string # Not applicable to regular users. In a publisher case, this is the publisher article DOI. (default: )
  --resource-title: string # Not applicable to regular users. In a publisher case, this is the publisher article title. (default: )
  --tags: list # List of tags to be associated with the article. Keywords can be used instead (default: [], e.g. [tag1, tag2])
  --timeline: record # shape: {firstOnline?: string, publisherAcceptance?: string, publisherPublication?: string}
  title: string # Title of article (e.g. Test article title)
]: any -> record<entity_id: int, location: string, warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/articles") $qp)
  let body = {"authors": $authors, "categories": $categories, "categories_by_source_id": $categories_by_source_id, "custom_fields": $custom_fields, "custom_fields_list": $custom_fields_list, "defined_type": $defined_type, "description": $description, "doi": $doi, "funding": $funding, "funding_list": $funding_list, "handle": $handle, "keywords": $keywords, "license": $license, "references": $references, "resource_doi": $resource_doi, "resource_title": $resource_title, "tags": $tags, "timeline": $timeline, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete project article
#
# DELETE /account/projects/{project_id}/articles/{article_id}
# operationId: private_project_article_delete
export def "account-projects-articles delete" [
  project_id: int
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, article_id: $article_id} | format pattern "/account/projects/{project_id}/articles/{article_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project article details
#
# GET /account/projects/{project_id}/articles/{article_id}
# operationId: private_project_article_details
export def "account-projects-articles details" [
  project_id: int
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, confidential_reason: string, created_date: string, description: string, embargo_date: string, embargo_reason: string, embargo_title: string, embargo_type: string, funding: string, funding_list: list<int>, has_linked_file: bool, is_active: bool, is_confidential: bool, is_embargoed: bool, is_metadata_record: bool, is_public: bool, license: record<name: string, url: string, value: int>, metadata_reason: string, modified_date: string, references: list<string>, size: int, status: string, tags: list<string>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, article_id: $article_id} | format pattern "/account/projects/{project_id}/articles/{article_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project article list files
#
# GET /account/projects/{project_id}/articles/{article_id}/files
# operationId: private_project_article_files
export def "account-projects-articles-files files" [
  project_id: int
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, article_id: $article_id} | format pattern "/account/projects/{project_id}/articles/{article_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project article file details
#
# GET /account/projects/{project_id}/articles/{article_id}/files/{file_id}
# operationId: private_project_article_file
export def "account-projects-articles-files file" [
  project_id: int
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_attached_to_public_version: bool, preview_state: string, status: string, upload_token: string, upload_url: string, viewer_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, article_id: $article_id, file_id: $file_id} | format pattern "/account/projects/{project_id}/articles/{article_id}/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List project collaborators
#
# GET /account/projects/{project_id}/collaborators
# operationId: private_project_collaborators_list
export def "account-projects-collaborators list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, role_name: string, status: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/collaborators"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite project collaborators
#
# POST /account/projects/{project_id}/collaborators
# operationId: private_project_collaborators_invite
export def "account-projects-collaborators invite" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # Text sent when inviting the user to the project (e.g. hey)
  --email: string # Collaborator email (e.g. user@domain.com)
  role_name: string@role-name-completer # Role of the the collaborator inside the project (e.g. viewer)
  --user-id: int # User id of the collaborator (format: int64, e.g. 100008)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/collaborators"))
  let body = {"comment": $comment, "email": $email, "role_name": $role_name, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove project collaborator
#
# DELETE /account/projects/{project_id}/collaborators/{user_id}
# operationId: private_project_collaborator__Delete
export def "account-projects-collaborators delete" [
  project_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, user_id: $user_id} | format pattern "/account/projects/{project_id}/collaborators/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Project Leave
#
# POST /account/projects/{project_id}/leave
# operationId: private_project_leave
export def "account-projects-leave leave" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/leave"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List project notes
#
# GET /account/projects/{project_id}/notes
# operationId: private_project_notes_list
export def "account-projects-notes list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> table<abstract: string, created_date: string, id: int, modified_date: string, user_id: int, user_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/notes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project note
#
# POST /account/projects/{project_id}/notes
# operationId: private_project_notes_create
export def "account-projects-notes create" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text of the note (e.g. note to remember)
]: any -> record<location: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/notes"))
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete project note
#
# DELETE /account/projects/{project_id}/notes/{note_id}
# operationId: private_project_note_delete
export def "account-projects-notes delete" [
  project_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, note_id: $note_id} | format pattern "/account/projects/{project_id}/notes/{note_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project note details
#
# GET /account/projects/{project_id}/notes/{note_id}
# operationId: private_project_note
export def "account-projects-notes note" [
  project_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, note_id: $note_id} | format pattern "/account/projects/{project_id}/notes/{note_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project note
#
# PUT /account/projects/{project_id}/notes/{note_id}
# operationId: private_project_note_update
export def "account-projects-notes update" [
  project_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text of the note (e.g. note to remember)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id, note_id: $note_id} | format pattern "/account/projects/{project_id}/notes/{note_id}"))
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Private Project Publish
#
# POST /account/projects/{project_id}/publish
# operationId: private_project_publish
export def "account-projects-publish publish" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/account/projects/{project_id}/publish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Articles
#
# GET /articles
# operationId: articles_list
export def "articles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --institution: int # only return articles from this institution (format: int64)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --group: int # only return articles from this group (format: int64)
  --resource-doi: string # only return articles with this resource_doi
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64)
  --doi: string # only return articles with this doi
  --handle: string # only return articles with this handle
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected.
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "institution" $institution "scalar") (serialize-qp "published_since" $published_since "scalar") (serialize-qp "modified_since" $modified_since "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "resource_doi" $resource_doi "scalar") (serialize-qp "item_type" $item_type "scalar") (serialize-qp "doi" $doi "scalar") (serialize-qp "handle" $handle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles" $qp)
  let extra_headers = {"X-Cursor": $x_cursor} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Articles Search
#
# POST /articles/search
# operationId: articles_search
export def "articles-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected.
  --doi: string # Only return articles with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return articles with this handle (e.g. 111084/m9.figshare.14074)
  --item-type: int # Only return articles with the respective type. Mapping for item_type is: 1 - Figure, 2 - Media, 3 - Dataset, 5 - Poster, 6 - Journal contribution, 7 - Presentation, 8 - Thesis, 9 - Software, 11 - Online resource, 12 - Preprint, 13 - Book, 14 - Conference contribution, 15 - Chapter, 16 - Peer review, 17 - Educational resource, 18 - Report, 19 - Standard, 20 - Composition, 21 - Funding, 22 - Physical object, 23 - Data management plan, 24 - Workflow, 25 - Monograph, 26 - Performance, 27 - Event, 28 - Service, 29 - Model (format: int64, e.g. 1)
  --order: string@order-completer # The field by which to order (default: created_date, e.g. published_date)
  --project-id: int # Only return articles in this project (format: int64, e.g. 1)
  --resource-doi: string # Only return articles with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> table<project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/articles/search")
  let body = {"doi": $doi, "handle": $handle, "item_type": $item_type, "order": $order, "project_id": $project_id, "resource_doi": $resource_doi, "group": $group, "institution": $institution, "limit": $limit, "modified_since": $modified_since, "offset": $offset, "order_direction": $order_direction, "page": $page, "page_size": $page_size, "published_since": $published_since, "search_for": $search_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Cursor": $x_cursor} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View article details
#
# GET /articles/{article_id}
# operationId: article_details
export def "articles details" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/articles/{article_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List article files
#
# GET /articles/{article_id}/files
# operationId: article_files
export def "articles-files files" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/articles/{article_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Article file details
#
# GET /articles/{article_id}/files/{file_id}
# operationId: article_file_details
export def "articles-files details" [
  article_id: int
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, file_id: $file_id} | format pattern "/articles/{article_id}/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List article versions
#
# GET /articles/{article_id}/versions
# operationId: article_versions
export def "articles-versions version-s" [
  article_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<url: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id} | format pattern "/articles/{article_id}/versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Article details for version
#
# GET /articles/{article_id}/versions/{v_number}
# operationId: article_version_details
export def "articles-versions details" [
  article_id: int
  v_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, custom_fields: table<is_mandatory: bool, name: string, value: string>, embargo_options: table<id: int, ip_name: string, type: string>, figshare_url: string, files: table<computed_md5: string, download_url: string, id: int, is_link_only: bool, name: string, size: int, supplied_md5: string>, resource_doi: string, resource_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, v_number: $v_number} | format pattern "/articles/{article_id}/versions/{v_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Article Confidentiality for article version
#
# GET /articles/{article_id}/versions/{v_number}/confidentiality
# operationId: article_version_confidentiality
export def "articles-versions-confidentiality confidentiality" [
  article_id: int
  v_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_confidential: bool, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, v_number: $v_number} | format pattern "/articles/{article_id}/versions/{v_number}/confidentiality"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Article Embargo for article version
#
# GET /articles/{article_id}/versions/{v_number}/embargo
# operationId: article_version_embargo
export def "articles-versions-embargo embargo" [
  article_id: int
  v_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<embargo_date: string, embargo_options: list<record>, embargo_reason: string, embargo_title: string, embargo_type: string, is_embargoed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({article_id: $article_id, v_number: $v_number} | format pattern "/articles/{article_id}/versions/{v_number}/embargo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Categories
#
# GET /categories
# operationId: categories_list
export def "categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Collections
#
# GET /collections
# operationId: collections_list
export def "collections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-1 # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --institution: int # only return collections from this institution (format: int64)
  --published-since: string # Filter by collection publishing date. Will only return collections published after the date. date(ISO 8601) YYYY-MM-DD
  --modified-since: string # Filter by collection modified date. Will only return collections published after the date. date(ISO 8601) YYYY-MM-DD
  --group: int # only return collections from this group (format: int64)
  --resource-doi: string # only return collections with this resource_doi
  --doi: string # only return collections with this doi
  --handle: string # only return collections with this handle
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected.
]: nothing -> table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "institution" $institution "scalar") (serialize-qp "published_since" $published_since "scalar") (serialize-qp "modified_since" $modified_since "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "resource_doi" $resource_doi "scalar") (serialize-qp "doi" $doi "scalar") (serialize-qp "handle" $handle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collections" $qp)
  let extra_headers = {"X-Cursor": $x_cursor} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Collections Search
#
# POST /collections/search
# operationId: collections_search
export def "collections-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected.
  --doi: string # Only return collections with this doi (e.g. 10.6084/m9.figshare.1407024)
  --handle: string # Only return collections with this handle (e.g. 10084/figshare.1407024)
  --order: string@order-completer-1 # The field by which to order. (default: created_date, e.g. published_date)
  --resource-doi: string # Only return collections with this resource_doi (e.g. 10.6084/m9.figshare.1407024)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> table<doi: string, handle: string, id: int, published_date: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections/search")
  let body = {"doi": $doi, "handle": $handle, "order": $order, "resource_doi": $resource_doi, "group": $group, "institution": $institution, "limit": $limit, "modified_since": $modified_since, "offset": $offset, "order_direction": $order_direction, "page": $page, "page_size": $page_size, "published_since": $published_since, "search_for": $search_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Cursor": $x_cursor} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Collection details
#
# GET /collections/{collection_id}
# operationId: collection_details
export def "collections details" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/collections/{collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Collection Articles
#
# GET /collections/{collection_id}/articles
# operationId: collection_articles
export def "collections-articles articles" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/collections/{collection_id}/articles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collection Versions list
#
# GET /collections/{collection_id}/versions
# operationId: collection_versions
export def "collections-versions version-s" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/collections/{collection_id}/versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collection Version details
#
# GET /collections/{collection_id}/versions/{version_id}
# operationId: collection_version_details
export def "collections-versions details" [
  collection_id: int
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<articles_count: int, authors: table<full_name: string, id: int, is_active: bool, orcid_id: string, url_name: string>, categories: table<id: int, parent_id: int, path: string, source_id: string, taxonomy_id: int, title: string>, citation: string, created_date: string, custom_fields: table<is_mandatory: bool, name: string, value: string>, description: string, funding: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>, group_id: int, group_resource_id: string, institution_id: int, modified_date: string, public: bool, references: list<string>, resource_doi: string, resource_id: string, resource_link: string, resource_title: string, resource_version: int, tags: list<string>, timeline: record<posted: string, revision: string, submission: string>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: $collection_id, version_id: $version_id} | format pattern "/collections/{collection_id}/versions/{version_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public File Download
#
# GET /file/download/{file_id}
# operationId: file_download
export def "file-download download" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/file/download/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Private Institution HRfeed Upload
#
# POST /institution/hrfeed/upload
# operationId: institution_hrfeed_upload
export def "institution-hrfeed-upload upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hrfeed: string # You can find an example in the Hr Feed section (format: binary)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institution/hrfeed/upload")
  let body = {"hrfeed": $hrfeed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Public Licenses
#
# GET /institutions/{institution_string_id}/articles/filter-by
# operationId: institution_articles
export def "institutions-articles-filter-by articles" [
  institution_string_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-id: string
  --filename: string
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "filename" $filename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({institution_string_id: $institution_string_id} | format pattern "/institutions/{institution_string_id}/articles/filter-by") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Item Types
#
# GET /item_types
# operationId: item_types_list
export def "item-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: int # Identifier of the group for which the item types are requested (format: int64, default: 0)
]: nothing -> table<icon: string, id: int, is_selectable: bool, name: string, public_description: string, string_id: string, url_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/item_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Licenses
#
# GET /licenses
# operationId: licenses_list
export def "licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, url: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licenses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Projects
#
# GET /projects
# operationId: projects_list
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Used for pagination with page_size (format: int64)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64)
  --order: string@order-completer-2 # The field by which to order. Default varies by endpoint/resource. (default: published_date)
  --order-direction: string@order-direction-completer # default: desc
  --institution: int # only return collections from this institution (format: int64)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD
  --group: int # only return collections from this group (format: int64)
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected.
]: nothing -> table<id: int, published_date: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "institution" $institution "scalar") (serialize-qp "published_since" $published_since "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let extra_headers = {"X-Cursor": $x_cursor} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Projects Search
#
# POST /projects/search
# operationId: projects_search
export def "projects-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-cursor: string # Unique hash used for bypassing the item retrieval limit of 9,000 entities. When using this parameter, please note that the offset parameter will not be available, but the limit parameter will still work as expected.
  --order: string@order-completer-2 # The field by which to order. (default: published_date, e.g. published_date)
  --group: int # only return collections from this group (format: int32, e.g. 2000013)
  --institution: int # only return collections from this institution (format: int32, e.g. 2000013)
  --limit: int # Number of results included on a page. Used for pagination with query (format: int64, e.g. 10)
  --modified-since: string # Filter by article modified date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --offset: int # Where to start the listing(the offset of the first result). Used for pagination with limit (format: int64, e.g. 0)
  --order-direction: string@order-direction-completer # Direction of ordering (default: desc, e.g. desc)
  --page: int # Page number. Used for pagination with page_size (format: int64, e.g. 1)
  --page-size: int # The number of results included on a page. Used for pagination with page (format: int64, default: 10, e.g. 10)
  --published-since: string # Filter by article publishing date. Will only return articles published after the date. date(ISO 8601) YYYY-MM-DD (e.g. 2017-12-22)
  --search-for: string # Search term (e.g. figshare)
]: any -> table<id: int, published_date: string, title: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects/search")
  let body = {"order": $order, "group": $group, "institution": $institution, "limit": $limit, "modified_since": $modified_since, "offset": $offset, "order_direction": $order_direction, "page": $page, "page_size": $page_size, "published_since": $published_since, "search_for": $search_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Cursor": $x_cursor} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Public Project
#
# GET /projects/{project_id}
# operationId: project_details
export def "projects details" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<collaborators: table<name: string, role_name: string, user_id: int>, description: string, figshare_url: string, funding: string, funding_list: table<funder_name: string, grant_code: string, id: int, is_user_defined: bool, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Public Project Articles
#
# GET /projects/{project_id}/articles
# operationId: project_articles
export def "projects-articles articles" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<defined_type: int, defined_type_name: string, doi: string, group_id: float, handle: string, id: int, published_date: string, thumb: string, timeline: record<posted: string, revision: string, submission: string>, title: string, url: string, url_private_api: string, url_private_html: string, url_public_api: string, url_public_html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: $project_id} | format pattern "/projects/{project_id}/articles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
