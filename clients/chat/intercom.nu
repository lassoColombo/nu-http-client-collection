# Auto-generated client for Intercom API v2.11
# Source: https://raw.githubusercontent.com/intercom/Intercom-OpenAPI/main/descriptions/2.11/api.intercom.io.yaml
# Auth: --token flag or $env.INTERCOM_API_TOKEN

const BASE_URL = "https://api.intercom.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INTERCOM_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.intercom.io" "https://api.eu.intercom.io" "https://api.au.intercom.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Intercom-Version-completer [] { ["1.0" "1.1" "1.2" "1.3" "1.4" "2.0" "2.1" "2.10" "2.11" "2.2" "2.3" "2.4" "2.5" "2.6" "2.7" "2.8" "2.9" "Preview"] }
def state-completer [] { ["draft" "published"] }
def message-type-completer [] { ["comment" "note"] }
def type-completer [] { ["admin"] }
def message-type-completer-1 [] { ["close"] }
def type-completer-1 [] { ["conversation_part"] }
def model-completer [] { ["company" "contact" "conversation"] }
def model-completer-1 [] { ["company" "contact"] }
def data-type-completer [] { ["boolean" "date" "datetime" "float" "integer" "string"] }
def message-type-completer-2 [] { ["email" "in_app"] }
def state-completer-1 [] { ["draft" "live"] }
def data-type-completer-1 [] { ["boolean" "datetime" "decimal" "files" "integer" "list" "string"] }
def category-completer [] { ["Back-office" "Customer" "Tracker"] }
def message-type-completer-3 [] { ["comment" "note" "quick_reply"] }
def state-completer-2 [] { ["in_progress" "resolved" "waiting_on_customer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "me identifyAdmin" } } | get name | first)
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

# Identify an admin
#
# GET /me
# operationId: identifyAdmin
export def "me identifyAdmin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, email: string, job_title: string, away_mode_enabled: bool, away_mode_reassign: bool, has_inbox_seat: bool, team_ids: list<int>, avatar: record<type: string, image_url: string>, email_verified: bool, app: record<type: string, id_code: string, name: string, region: string, timezone: string, created_at: int, identity_verification: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set an admin to away
#
# PUT /admins/{admin_id}/away
# operationId: setAwayAdmin
export def "admins-away setAwayAdmin" [
  admin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --away-mode-enabled: oneof<nothing, bool> # Set to "true" to change the status of the admin to away. (default: true, e.g. true)
  --away-mode-reassign: oneof<nothing, bool> # Set to "true" to assign any new conversation replies to your default inbox. (default: false, e.g. false)
]: any -> record<type: string, id: string, name: string, email: string, job_title: string, away_mode_enabled: bool, away_mode_reassign: bool, has_inbox_seat: bool, team_ids: list<int>, avatar: record<image_url: string>, team_priority_level: record<primary_team_ids: list<int>, secondary_team_ids: list<int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admins/($admin_id)/away")
  let body = {away_mode_enabled: $away_mode_enabled, away_mode_reassign: $away_mode_reassign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all activity logs
#
# GET /admins/activity_logs
# operationId: listActivityLogs
export def "admins-activity-logs listActivityLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at-after: string # The start date that you request data for. It must be formatted as a UNIX timestamp. (e.g. 1677253093)
  --created-at-before: string # The end date that you request data for. It must be formatted as a UNIX timestamp. (e.g. 1677861493)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, activity_logs: table<id: string, performed_by: record, metadata: record, created_at: int, activity_type: string, activity_description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_at_after" $created_at_after "scalar") (serialize-qp "created_at_before" $created_at_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admins/activity_logs" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all admins
#
# GET /admins
# operationId: listAdmins
export def "admins listAdmins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-avatar: oneof<nothing, bool> # If set to true, the response will include the admin's avatar object containing the image URL. Defaults to false. (e.g. true)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, admins: table<type: string, id: string, name: string, email: string, job_title: string, away_mode_enabled: bool, away_mode_reassign: bool, has_inbox_seat: bool, team_ids: list, avatar: record, team_priority_level: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display_avatar" $display_avatar "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admins" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an admin
#
# GET /admins/{admin_id}
# operationId: retrieveAdmin
export def "admins retrieveAdmin" [
  admin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, email: string, job_title: string, away_mode_enabled: bool, away_mode_reassign: bool, has_inbox_seat: bool, team_ids: list<int>, avatar: record<image_url: string>, team_priority_level: record<primary_team_ids: list<int>, secondary_team_ids: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admins/($admin_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all articles
#
# GET /articles
# operationId: listArticles
export def "articles listArticles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, data: table<type: string, id: string, workspace_id: string, title: string, description: string, body: string, author_id: int, state: string, created_at: int, updated_at: int, url: string, parent_id: int, parent_ids: list, parent_type: string, default_locale: string, translated_content: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an article
#
# POST /articles
# operationId: createArticle
# --translated_content shape: {type?: "article_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
export def "articles createArticle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  title: string # The title of the article.For multilingual articles, this will be the title of the default language's content. (e.g. Thanks for everything)
  --description: string # The description of the article. For multilingual articles, this will be the description of the default language's content. (e.g. Description of the Article)
  --body-body: string # The content of the article. For multilingual articles, this will be the body of the default language's content. (e.g. <p>This is the body in html</p>)
  author_id: int # The id of the author of the article. For multilingual articles, this will be the id of the author of the default language's content. Must be a teammate on the help center's workspace. (e.g. 1295)
  --state: string@state-completer # Whether the article will be `published` or will be a `draft`. Defaults to draft. For multilingual articles, this will be the state of the default language's content. (e.g. draft)
  --parent-id: int # The id of the article's parent collection or section. An article without this field stands alone. (e.g. 18)
  --parent-type: string # The type of parent, which can either be a `collection` or `section`. (e.g. collection)
  --translated-content: record # The Translated Content of an Article. The keys are the locale codes and the values are the translated content of the article. — shape: {type?: "article_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
]: any -> record<statistics: record<type: string, views: int, conversions: int, reactions: int, happy_reaction_percentage: float, neutral_reaction_percentage: float, sad_reaction_percentage: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/articles")
  let body = {title: $title, description: $description, body: $body_body, author_id: $author_id, state: $state, parent_id: $parent_id, parent_type: $parent_type, translated_content: $translated_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an article
#
# GET /articles/{article_id}
# operationId: retrieveArticle
export def "articles retrieveArticle" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<statistics: record<type: string, views: int, conversions: int, reactions: int, happy_reaction_percentage: float, neutral_reaction_percentage: float, sad_reaction_percentage: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/articles/($article_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an article
#
# PUT /articles/{article_id}
# operationId: updateArticle
# --translated_content shape: {type?: "article_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
export def "articles updateArticle" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --title: string # The title of the article.For multilingual articles, this will be the title of the default language's content. (e.g. Thanks for everything)
  --description: string # The description of the article. For multilingual articles, this will be the description of the default language's content. (e.g. Description of the Article)
  --body-body: string # The content of the article. For multilingual articles, this will be the body of the default language's content. (e.g. <p>This is the body in html</p>)
  --author-id: int # The id of the author of the article. For multilingual articles, this will be the id of the author of the default language's content. Must be a teammate on the help center's workspace. (e.g. 1295)
  --state: string@state-completer # Whether the article will be `published` or will be a `draft`. Defaults to draft. For multilingual articles, this will be the state of the default language's content. (e.g. draft)
  --parent-id: string # The id of the article's parent collection or section. An article without this field stands alone. (e.g. 18)
  --parent-type: string # The type of parent, which can either be a `collection` or `section`. (e.g. collection)
  --translated-content: record # The Translated Content of an Article. The keys are the locale codes and the values are the translated content of the article. — shape: {type?: "article_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
]: any -> record<statistics: record<type: string, views: int, conversions: int, reactions: int, happy_reaction_percentage: float, neutral_reaction_percentage: float, sad_reaction_percentage: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/articles/($article_id)")
  let body = {title: $title, description: $description, body: $body_body, author_id: $author_id, state: $state, parent_id: $parent_id, parent_type: $parent_type, translated_content: $translated_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an article
#
# DELETE /articles/{article_id}
# operationId: deleteArticle
export def "articles delete" [
  article_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/articles/($article_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for articles
#
# GET /articles/search
# operationId: searchArticles
export def "articles-search searchArticles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phrase: string # The phrase within your articles to search for. (e.g. Getting started)
  --state: string # The state of the Articles returned. One of `published`, `draft` or `all`. (e.g. published)
  --help-center-id: int # The ID of the Help Center to search in. (e.g. 123)
  --highlight: oneof<nothing, bool> # Return a highlighted version of the matching content within your articles. Refer to the response schema for more details. (e.g. false)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, total_count: int, data: record<articles: list<record>, highlights: list<record>>, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phrase" $phrase "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "help_center_id" $help_center_id "scalar") (serialize-qp "highlight" $highlight "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles/search" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all collections
#
# GET /help_center/collections
# operationId: listAllCollections
export def "help-center-collections listAllCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, data: table<id: string, workspace_id: string, name: string, description: string, created_at: int, updated_at: int, url: string, icon: string, order: int, default_locale: string, translated_content: record, parent_id: string, help_center_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/help_center/collections" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a collection
#
# POST /help_center/collections
# operationId: createCollection
# --translated_content shape: {type: "group_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
export def "help-center-collections createCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  name: string # The name of the collection. For multilingual collections, this will be the name of the default language's content. (e.g. collection 51)
  --description: string # The description of the collection. For multilingual collections, this will be the description of the default language's content. (e.g. English description)
  --translated-content: record # The Translated Content of an Group. The keys are the locale codes and the values are the translated content of the Group. — shape: {type: "group_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
  --parent-id: string # The id of the parent collection. If `null` then it will be created as the first level collection. (nullable, e.g. 6871118)
  --help-center-id: int # The id of the help center where the collection will be created. If `null` then it will be created in the default help center. (nullable, e.g. 123)
]: any -> record<id: string, workspace_id: string, name: string, description: string, created_at: int, updated_at: int, url: string, icon: string, order: int, default_locale: string, translated_content: record<type: string, ar: record<type: string, name: string, description: string>, bg: record<type: string, name: string, description: string>, bs: record<type: string, name: string, description: string>, ca: record<type: string, name: string, description: string>, cs: record<type: string, name: string, description: string>, da: record<type: string, name: string, description: string>, de: record<type: string, name: string, description: string>, el: record<type: string, name: string, description: string>, en: record<type: string, name: string, description: string>, es: record<type: string, name: string, description: string>, et: record<type: string, name: string, description: string>, fi: record<type: string, name: string, description: string>, fr: record<type: string, name: string, description: string>, he: record<type: string, name: string, description: string>, hr: record<type: string, name: string, description: string>, hu: record<type: string, name: string, description: string>, id: record<type: string, name: string, description: string>, it: record<type: string, name: string, description: string>, ja: record<type: string, name: string, description: string>, ko: record<type: string, name: string, description: string>, lt: record<type: string, name: string, description: string>, lv: record<type: string, name: string, description: string>, mn: record<type: string, name: string, description: string>, nb: record<type: string, name: string, description: string>, nl: record<type: string, name: string, description: string>, pl: record<type: string, name: string, description: string>, pt: record<type: string, name: string, description: string>, ro: record<type: string, name: string, description: string>, ru: record<type: string, name: string, description: string>, sl: record<type: string, name: string, description: string>, sr: record<type: string, name: string, description: string>, sv: record<type: string, name: string, description: string>, tr: record<type: string, name: string, description: string>, vi: record<type: string, name: string, description: string>, pt_BR: record<type: string, name: string, description: string>, zh_CN: record<type: string, name: string, description: string>, zh_TW: record<type: string, name: string, description: string>>, parent_id: string, help_center_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/help_center/collections")
  let body = {name: $name, description: $description, translated_content: $translated_content, parent_id: $parent_id, help_center_id: $help_center_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a collection
#
# GET /help_center/collections/{collection_id}
# operationId: retrieveCollection
export def "help-center-collections retrieveCollection" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<id: string, workspace_id: string, name: string, description: string, created_at: int, updated_at: int, url: string, icon: string, order: int, default_locale: string, translated_content: record<type: string, ar: record<type: string, name: string, description: string>, bg: record<type: string, name: string, description: string>, bs: record<type: string, name: string, description: string>, ca: record<type: string, name: string, description: string>, cs: record<type: string, name: string, description: string>, da: record<type: string, name: string, description: string>, de: record<type: string, name: string, description: string>, el: record<type: string, name: string, description: string>, en: record<type: string, name: string, description: string>, es: record<type: string, name: string, description: string>, et: record<type: string, name: string, description: string>, fi: record<type: string, name: string, description: string>, fr: record<type: string, name: string, description: string>, he: record<type: string, name: string, description: string>, hr: record<type: string, name: string, description: string>, hu: record<type: string, name: string, description: string>, id: record<type: string, name: string, description: string>, it: record<type: string, name: string, description: string>, ja: record<type: string, name: string, description: string>, ko: record<type: string, name: string, description: string>, lt: record<type: string, name: string, description: string>, lv: record<type: string, name: string, description: string>, mn: record<type: string, name: string, description: string>, nb: record<type: string, name: string, description: string>, nl: record<type: string, name: string, description: string>, pl: record<type: string, name: string, description: string>, pt: record<type: string, name: string, description: string>, ro: record<type: string, name: string, description: string>, ru: record<type: string, name: string, description: string>, sl: record<type: string, name: string, description: string>, sr: record<type: string, name: string, description: string>, sv: record<type: string, name: string, description: string>, tr: record<type: string, name: string, description: string>, vi: record<type: string, name: string, description: string>, pt_BR: record<type: string, name: string, description: string>, zh_CN: record<type: string, name: string, description: string>, zh_TW: record<type: string, name: string, description: string>>, parent_id: string, help_center_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/help_center/collections/($collection_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a collection
#
# PUT /help_center/collections/{collection_id}
# operationId: updateCollection
# --translated_content shape: {type: "group_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
export def "help-center-collections updateCollection" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --name: string # The name of the collection. For multilingual collections, this will be the name of the default language's content. (e.g. collection 51)
  --description: string # The description of the collection. For multilingual collections, this will be the description of the default language's content. (e.g. English description)
  --translated-content: record # The Translated Content of an Group. The keys are the locale codes and the values are the translated content of the Group. — shape: {type: "group_translated_content", ar?: record, bg?: record, bs?: record, ca?: record, cs?: record, da?: record, de?: record, el?: record, en?: record, es?: record, et?: record, fi?: record, fr?: record, he?: record, hr?: record, hu?: record, id?: record, it?: record, ja?: record, ko?: record, lt?: record, lv?: record, mn?: record, nb?: record, nl?: record, pl?: record, pt?: record, ro?: record, ru?: record, sl?: record, sr?: record, sv?: record, tr?: record, vi?: record, pt-BR?: record, zh-CN?: record, zh-TW?: record}
  --parent-id: string # The id of the parent collection. If `null` then it will be updated as the first level collection. (nullable, e.g. 6871118)
]: any -> record<id: string, workspace_id: string, name: string, description: string, created_at: int, updated_at: int, url: string, icon: string, order: int, default_locale: string, translated_content: record<type: string, ar: record<type: string, name: string, description: string>, bg: record<type: string, name: string, description: string>, bs: record<type: string, name: string, description: string>, ca: record<type: string, name: string, description: string>, cs: record<type: string, name: string, description: string>, da: record<type: string, name: string, description: string>, de: record<type: string, name: string, description: string>, el: record<type: string, name: string, description: string>, en: record<type: string, name: string, description: string>, es: record<type: string, name: string, description: string>, et: record<type: string, name: string, description: string>, fi: record<type: string, name: string, description: string>, fr: record<type: string, name: string, description: string>, he: record<type: string, name: string, description: string>, hr: record<type: string, name: string, description: string>, hu: record<type: string, name: string, description: string>, id: record<type: string, name: string, description: string>, it: record<type: string, name: string, description: string>, ja: record<type: string, name: string, description: string>, ko: record<type: string, name: string, description: string>, lt: record<type: string, name: string, description: string>, lv: record<type: string, name: string, description: string>, mn: record<type: string, name: string, description: string>, nb: record<type: string, name: string, description: string>, nl: record<type: string, name: string, description: string>, pl: record<type: string, name: string, description: string>, pt: record<type: string, name: string, description: string>, ro: record<type: string, name: string, description: string>, ru: record<type: string, name: string, description: string>, sl: record<type: string, name: string, description: string>, sr: record<type: string, name: string, description: string>, sv: record<type: string, name: string, description: string>, tr: record<type: string, name: string, description: string>, vi: record<type: string, name: string, description: string>, pt_BR: record<type: string, name: string, description: string>, zh_CN: record<type: string, name: string, description: string>, zh_TW: record<type: string, name: string, description: string>>, parent_id: string, help_center_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/help_center/collections/($collection_id)")
  let body = {name: $name, description: $description, translated_content: $translated_content, parent_id: $parent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a collection
#
# DELETE /help_center/collections/{collection_id}
# operationId: deleteCollection
export def "help-center-collections delete" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/help_center/collections/($collection_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Help Center
#
# GET /help_center/help_centers/{help_center_id}
# operationId: retrieveHelpCenter
export def "help-center-help-centers retrieveHelpCenter" [
  help_center_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<id: string, workspace_id: string, created_at: int, updated_at: int, identifier: string, website_turned_on: bool, display_name: string, url: string, custom_domain: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/help_center/help_centers/($help_center_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Help Centers
#
# GET /help_center/help_centers
# operationId: listHelpCenters
export def "help-center-help-centers listHelpCenters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<id: string, workspace_id: string, created_at: int, updated_at: int, identifier: string, website_turned_on: bool, display_name: string, url: string, custom_domain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/help_center/help_centers" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update a company
#
# POST /companies
# operationId: createOrUpdateCompany
export def "companies createOrUpdateCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --name: string # The name of the Company (e.g. Intercom)
  --company-id: string # The company id you have defined for the company. Can't be updated (e.g. 625e90fc55ab113b6d92175f)
  --plan: string # The name of the plan you have associated with the company. (e.g. Enterprise)
  --size: int # The number of employees in this company. (e.g. 100)
  --website: string # The URL for this company's website. Please note that the value specified here is not validated. Accepts any string. (e.g. https://www.example.com)
  --industry: string # The industry that this company operates in. (e.g. Manufacturing)
  --custom-attributes: record # A hash of key/value pairs containing any other data about the company you want Intercom to store. (e.g. {paid_subscriber: true, monthly_spend: 155.5, team_mates: 9})
  --remote-created-at: int # The time the company was created by you. (e.g. 1394531169)
  --monthly-spend: int # How much revenue the company generates for your business. Note that this will truncate floats. i.e. it only allow for whole integers, 155.98 will be truncated to 155. Note that this has an upper limit of 2**31-1 or 2147483647.. (e.g. 1000)
]: any -> record<type: string, id: string, name: string, app_id: string, plan: record<type: string, id: string, name: string>, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record<type: string, tags: list<record>>, segments: record<type: string, segments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies")
  let body = {name: $name, company_id: $company_id, plan: $plan, size: $size, website: $website, industry: $industry, custom_attributes: $custom_attributes, remote_created_at: $remote_created_at, monthly_spend: $monthly_spend} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve companies
#
# GET /companies
# operationId: retrieveCompany
export def "companies retrieveCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The `name` of the company to filter by. (e.g. my company)
  --company-id: string # The `company_id` of the company to filter by. (e.g. 12345)
  --tag-id: string # The `tag_id` of the company to filter by. (e.g. 678910)
  --segment-id: string # The `segment_id` of the company to filter by. (e.g. 98765)
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, data: table<type: string, id: string, name: string, app_id: string, plan: record, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record, segments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "company_id" $company_id "scalar") (serialize-qp "tag_id" $tag_id "scalar") (serialize-qp "segment_id" $segment_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/companies" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a company by ID
#
# GET /companies/{company_id}
# operationId: RetrieveACompanyById
export def "companies RetrieveACompanyById" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, app_id: string, plan: record<type: string, id: string, name: string>, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record<type: string, tags: list<record>>, segments: record<type: string, segments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($company_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a company
#
# PUT /companies/{company_id}
# operationId: UpdateCompany
export def "companies UpdateCompany" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, app_id: string, plan: record<type: string, id: string, name: string>, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record<type: string, tags: list<record>>, segments: record<type: string, segments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($company_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a company
#
# DELETE /companies/{company_id}
# operationId: deleteCompany
export def "companies delete" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($company_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List attached contacts
#
# GET /companies/{company_id}/contacts
# operationId: ListAttachedContacts
export def "companies-contacts ListAttachedContacts" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to return per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record, tags: record, notes: record, companies: record, location: record, social_profiles: record>, total_count: int, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($company_id)/contacts" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List attached segments for companies
#
# GET /companies/{company_id}/segments
# operationId: ListAttachedSegmentsForCompanies
export def "companies-segments ListAttachedSegmentsForCompanies" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, name: string, created_at: int, updated_at: int, person_type: string, count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($company_id)/segments")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all companies
#
# POST /companies/list
# operationId: listAllCompanies
export def "companies-list listAllCompanies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to return per page. Defaults to 15 (e.g. 15)
  --order: string # `asc` or `desc`. Return the companies in ascending or descending order. Defaults to desc (e.g. desc)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, data: table<type: string, id: string, name: string, app_id: string, plan: record, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record, segments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/companies/list" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scroll over all companies
#
# GET /companies/scroll
# operationId: scrollOverAllCompanies
export def "companies-scroll scrollOverAllCompanies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scroll-param: string
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, name: string, app_id: string, plan: record, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record, segments: record>, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, scroll_param: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scroll_param" $scroll_param "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/companies/scroll" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a Contact to a Company
#
# POST /contacts/{contact_id}/companies
# operationId: attachContactToACompany
export def "contacts-companies attachContactToACompany" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  id: string # The unique identifier for the company which is given by Intercom (e.g. 58a430d35458202d41b1e65b)
]: any -> record<type: string, id: string, name: string, app_id: string, plan: record<type: string, id: string, name: string>, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record<type: string, tags: list<record>>, segments: record<type: string, segments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/companies")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List attached companies for contact
#
# GET /contacts/{contact_id}/companies
# operationId: listCompaniesForAContact
export def "contacts-companies listCompaniesForAContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, companies: table<type: string, id: string, name: string, app_id: string, plan: record, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record, segments: record>, total_count: int, pages: record<type: string, page: int, next: string, per_page: int, total_pages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($contact_id)/companies" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a contact from a company
#
# DELETE /contacts/{contact_id}/companies/{company_id}
# operationId: detachContactFromACompany
export def "contacts-companies detachContactFromACompany" [
  contact_id: string
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, app_id: string, plan: record<type: string, id: string, name: string>, company_id: string, remote_created_at: int, created_at: int, updated_at: int, last_request_at: int, size: int, website: string, industry: string, monthly_spend: int, session_count: int, user_count: int, custom_attributes: record, tags: record<type: string, tags: list<record>>, segments: record<type: string, segments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/companies/($company_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all notes
#
# GET /contacts/{contact_id}/notes
# operationId: listNotes
export def "contacts-notes listNotes" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, created_at: int, contact: record, author: record, body: string>, total_count: int, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($contact_id)/notes" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a note
#
# POST /contacts/{contact_id}/notes
# operationId: createNote
export def "contacts-notes createNote" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --body-body: string # The text of the note. (e.g. New note)
  --admin-id: string # The unique identifier of a given admin. (e.g. 123)
]: any -> record<type: string, id: string, created_at: int, contact: record<type: string, id: string>, author: record<type: string, id: string, name: string, email: string, job_title: string, away_mode_enabled: bool, away_mode_reassign: bool, has_inbox_seat: bool, team_ids: list<int>, avatar: record<image_url: string>, team_priority_level: record<primary_team_ids: list, secondary_team_ids: list>>, body: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/notes")
  let body = {body: $body_body, admin_id: $admin_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List attached segments for contact
#
# GET /contacts/{contact_id}/segments
# operationId: listSegmentsForAContact
export def "contacts-segments listSegmentsForAContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, name: string, created_at: int, updated_at: int, person_type: string, count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/segments")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List subscriptions for a contact
#
# GET /contacts/{contact_id}/subscriptions
# operationId: listSubscriptionsForAContact
export def "contacts-subscriptions listSubscriptionsForAContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, state: string, default_translation: record, translations: list, consent_type: string, content_types: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/subscriptions")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add subscription to a contact
#
# POST /contacts/{contact_id}/subscriptions
# operationId: attachSubscriptionTypeToContact
export def "contacts-subscriptions attachSubscriptionTypeToContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  id: string # The unique identifier for the subscription which is given by Intercom (e.g. 37846)
  consent_type: string # The consent_type of a subscription, opt_out or opt_in. (e.g. opt_in)
]: any -> record<type: string, id: string, state: string, default_translation: record<name: string, description: string, locale: string>, translations: table<name: string, description: string, locale: string>, consent_type: string, content_types: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/subscriptions")
  let body = {id: $id, consent_type: $consent_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove subscription from a contact
#
# DELETE /contacts/{contact_id}/subscriptions/{subscription_id}
# operationId: detachSubscriptionTypeToContact
export def "contacts-subscriptions detachSubscriptionTypeToContact" [
  contact_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, state: string, default_translation: record<name: string, description: string, locale: string>, translations: table<name: string, description: string, locale: string>, consent_type: string, content_types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/subscriptions/($subscription_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tags attached to a contact
#
# GET /contacts/{contact_id}/tags
# operationId: listTagsForAContact
export def "contacts-tags listTagsForAContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, name: string, applied_at: int, applied_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/tags")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add tag to a contact
#
# POST /contacts/{contact_id}/tags
# operationId: attachTagToContact
export def "contacts-tags attachTagToContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  id: string # The unique identifier for the tag which is given by Intercom (e.g. 7522907)
]: any -> record<type: string, id: string, name: string, applied_at: int, applied_by: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/tags")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove tag from a contact
#
# DELETE /contacts/{contact_id}/tags/{tag_id}
# operationId: detachTagFromContact
export def "contacts-tags detachTagFromContact" [
  contact_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, applied_at: int, applied_by: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/tags/($tag_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a contact
#
# PUT /contacts/{contact_id}
# operationId: UpdateContact
export def "contacts UpdateContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --role: string # The role of the contact.
  --external-id: string # A unique identifier for the contact which is given to Intercom
  --email: string # The contacts email (e.g. jdoe@example.com)
  --phone: string # The contacts phone (nullable, e.g. +353871234567)
  --name: string # The contacts name (nullable, e.g. John Doe)
  --avatar: string # An image URL containing the avatar of a contact (nullable, e.g. https://www.example.com/avatar_image.jpg)
  --signed-up-at: int # (Unix timestamp in seconds) The time specified for when a contact signed up. (nullable, format: date-time, e.g. 1571672154)
  --last-seen-at: int # (Unix timestamp in seconds) The time when the contact was last seen (either where the Intercom Messenger was installed or when specified manually). (nullable, format: date-time, e.g. 1571672154)
  --owner-id: int # The id of an admin that has been assigned account ownership of the contact (nullable, e.g. 123)
  --unsubscribed-from-emails: oneof<nothing, bool> # Whether the contact is unsubscribed from emails (nullable, e.g. true)
  --custom-attributes: record # The custom attributes which are set for the contact (nullable)
]: any -> record<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record<type: string, image_url: string>, tags: record<data: list<record>, url: string, total_count: int, has_more: bool>, notes: record<data: list<record>, url: string, total_count: int, has_more: bool>, companies: record<type: string, data: list<record>, url: string, total_count: int, has_more: bool>, location: record<type: string, country: string, region: string, city: string>, social_profiles: record<data: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)")
  let body = {role: $role, external_id: $external_id, email: $email, phone: $phone, name: $name, avatar: $avatar, signed_up_at: $signed_up_at, last_seen_at: $last_seen_at, owner_id: $owner_id, unsubscribed_from_emails: $unsubscribed_from_emails, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a contact
#
# GET /contacts/{contact_id}
# operationId: ShowContact
export def "contacts ShowContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record<type: string, image_url: string>, tags: record<data: list<record>, url: string, total_count: int, has_more: bool>, notes: record<data: list<record>, url: string, total_count: int, has_more: bool>, companies: record<type: string, data: list<record>, url: string, total_count: int, has_more: bool>, location: record<type: string, country: string, region: string, city: string>, social_profiles: record<data: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a contact
#
# DELETE /contacts/{contact_id}
# operationId: DeleteContact
export def "contacts DeleteContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, external_id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge a lead and a user
#
# POST /contacts/merge
# operationId: MergeContact
export def "contacts-merge MergeContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --body-from: string # The unique identifier for the contact to merge away from. Must be a lead. (e.g. 5d70dd30de4efd54f42fd526)
  --body-into: string # The unique identifier for the contact to merge into. Must be a user. (e.g. 5ba682d23d7cf92bef87bfd4)
]: any -> record<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record<type: string, image_url: string>, tags: record<data: list<record>, url: string, total_count: int, has_more: bool>, notes: record<data: list<record>, url: string, total_count: int, has_more: bool>, companies: record<type: string, data: list<record>, url: string, total_count: int, has_more: bool>, location: record<type: string, country: string, region: string, city: string>, social_profiles: record<data: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/merge")
  let body = {from: $body_from, into: $body_into} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search contacts
#
# POST /contacts/search
# operationId: SearchContacts
# --pagination shape: {per_page: int, starting_after?: string}
export def "contacts-search SearchContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --body-query: any
  --pagination: record # shape: {per_page: int, starting_after?: string}
]: any -> record<type: string, data: table<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record, tags: record, notes: record, companies: record, location: record, social_profiles: record>, total_count: int, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/search")
  let body = {query: $body_query, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all contacts
#
# GET /contacts
# operationId: ListContacts
export def "contacts ListContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of results to fetch. Defaults to first page (e.g. 1)
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --starting-after: string # String used to get the next page of conversations.
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record, tags: record, notes: record, companies: record, location: record, social_profiles: record>, total_count: int, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "starting_after" $starting_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create contact
#
# POST /contacts
# operationId: CreateContact
export def "contacts CreateContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --role: string # The role of the contact. (e.g. user)
  --external-id: string # A unique identifier for the contact which is given to Intercom (e.g. 625e90fc55ab113b6d92175f)
  --email: string # The contacts email (e.g. jdoe@example.com)
  --phone: string # The contacts phone (nullable, e.g. +353871234567)
  --name: string # The contacts name (nullable, e.g. John Doe)
  --avatar: string # An image URL containing the avatar of a contact (nullable, e.g. https://www.example.com/avatar_image.jpg)
  --signed-up-at: int # (Unix timestamp in seconds) The time specified for when a contact signed up. (nullable, format: date-time, e.g. 1571672154)
  --last-seen-at: int # (Unix timestamp in seconds) The time when the contact was last seen (either where the Intercom Messenger was installed or when specified manually). (nullable, format: date-time, e.g. 1571672154)
  --owner-id: int # The id of an admin that has been assigned account ownership of the contact (nullable, e.g. 123)
  --unsubscribed-from-emails: oneof<nothing, bool> # Whether the contact is unsubscribed from emails (nullable, e.g. true)
  --custom-attributes: record # The custom attributes which are set for the contact (nullable, e.g. {paid_subscriber: true, monthly_spend: 155.5, team_mates: 1})
]: any -> record<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record<type: string, image_url: string>, tags: record<data: list<record>, url: string, total_count: int, has_more: bool>, notes: record<data: list<record>, url: string, total_count: int, has_more: bool>, companies: record<type: string, data: list<record>, url: string, total_count: int, has_more: bool>, location: record<type: string, country: string, region: string, city: string>, social_profiles: record<data: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts")
  let body = {role: $role, external_id: $external_id, email: $email, phone: $phone, name: $name, avatar: $avatar, signed_up_at: $signed_up_at, last_seen_at: $last_seen_at, owner_id: $owner_id, unsubscribed_from_emails: $unsubscribed_from_emails, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive contact
#
# POST /contacts/{contact_id}/archive
# operationId: ArchiveContact
export def "contacts-archive ArchiveContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, external_id: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/archive")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive contact
#
# POST /contacts/{contact_id}/unarchive
# operationId: UnarchiveContact
export def "contacts-unarchive UnarchiveContact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, external_id: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($contact_id)/unarchive")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add tag to a conversation
#
# POST /conversations/{conversation_id}/tags
# operationId: attachTagToConversation
export def "conversations-tags attachTagToConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  id: string # The unique identifier for the tag which is given by Intercom (e.g. 7522907)
  admin_id: string # The unique identifier for the admin which is given by Intercom. (e.g. 780)
]: any -> record<type: string, id: string, name: string, applied_at: int, applied_by: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/tags")
  let body = {id: $id, admin_id: $admin_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove tag from a conversation
#
# DELETE /conversations/{conversation_id}/tags/{tag_id}
# operationId: detachTagFromConversation
export def "conversations-tags detachTagFromConversation" [
  conversation_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  admin_id: string # The unique identifier for the admin which is given by Intercom. (e.g. 123)
]: any -> record<type: string, id: string, name: string, applied_at: int, applied_by: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/tags/($tag_id)")
  let body = {admin_id: $admin_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all conversations
#
# GET /conversations
# operationId: listConversations
export def "conversations listConversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # How many results per page (default: 20)
  --starting-after: string # String used to get the next page of conversations.
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, conversations: table<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record, conversation_rating: record, source: record, contacts: record, teammates: record, custom_attributes: any, first_contact_reply: record, sla_applied: record, statistics: record, linked_objects: record, ai_agent_participated: bool, ai_agent: record>, total_count: int, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "starting_after" $starting_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a conversation
#
# POST /conversations
# operationId: createConversation
# --from shape: {type: "lead"|"user"|"contact", id: string}
export def "conversations createConversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --body-from: record # shape: {type: "lead"|"user"|"contact", id: string}
  --body-body: string # The content of the message. HTML is not supported. (e.g. Hello)
  --subject: string # The title of the email. Only applicable if the message type is email. (e.g. Thanks for everything)
  --attachment-urls: list # A list of image URLs that will be added as attachments. You can include up to 10 URLs.
  --created-at: int # The time the conversation was created as a UTC Unix timestamp. If not provided, the current time will be used. This field is only recommneded for migrating past conversations from another source into Intercom. (format: date-time, e.g. 1671028894)
]: any -> record<type: string, id: string, created_at: int, subject: string, body: string, message_type: string, conversation_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations")
  let body = {from: $body_from, body: $body_body, subject: $subject, attachment_urls: $attachment_urls, created_at: $created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a conversation
#
# GET /conversations/{conversation_id}
# operationId: retrieveConversation
export def "conversations retrieveConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-as: string # Set to plaintext to retrieve conversation messages in plain text. (e.g. plaintext)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display_as" $display_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a conversation
#
# PUT /conversations/{conversation_id}
# operationId: updateConversation
export def "conversations updateConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-as: string # Set to plaintext to retrieve conversation messages in plain text. (e.g. plaintext)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --read: oneof<nothing, bool> # Mark a conversation as read within Intercom. (e.g. true)
  --custom-attributes: any
]: any -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "display_as" $display_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)" $qp)
  let body = {read: $read, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search conversations
#
# POST /conversations/search
# operationId: searchConversations
# --pagination shape: {per_page: int, starting_after?: string}
export def "conversations-search searchConversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --body-query: any
  --pagination: record # shape: {per_page: int, starting_after?: string}
]: any -> record<type: string, conversations: table<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record, conversation_rating: record, source: record, contacts: record, teammates: record, custom_attributes: any, first_contact_reply: record, sla_applied: record, statistics: record, linked_objects: record, ai_agent_participated: bool, ai_agent: record>, total_count: int, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/search")
  let body = {query: $body_query, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reply to a conversation
#
# POST /conversations/{conversation_id}/reply
# operationId: replyConversation
# --attachment_files item shape: {content_type: string, data: string, name: string}
export def "conversations-reply replyConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --message-type: string@message-type-completer
  --type: string@type-completer # e.g. admin
  --body-body: string # The text body of the reply. Notes accept some HTML formatting. Must be present for comment and note message types. (e.g. Hello there!)
  --admin-id: string # The id of the admin who is authoring the comment. (e.g. 3156780)
  --created-at: int # The time the reply was created. If not provided, the current time will be used. (e.g. 1590000000)
  --attachment-urls: list # A list of image URLs that will be added as attachments. You can include up to 10 URLs.
  --attachment-files: list # A list of files that will be added as attachments. You can include up to 10 files — item shape: {content_type: string, data: string, name: string}
]: any -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/reply")
  let body = {message_type: $message_type, type: $type, body: $body_body, admin_id: $admin_id, created_at: $created_at, attachment_urls: $attachment_urls, attachment_files: $attachment_files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manage a conversation
#
# POST /conversations/{conversation_id}/parts
# operationId: manageConversation
export def "conversations-parts manageConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --message-type: string@message-type-completer-1 # e.g. close
  --type: string@type-completer # e.g. admin
  --admin-id: string # The id of the admin who is performing the action. (e.g. 12345)
  --body-body: string # Optionally you can leave a message in the conversation to provide additional context to the user and other teammates. (e.g.  This conversation is now closed!)
  --snoozed-until: int # The time you want the conversation to reopen. (format: timestamp, e.g. 1673609604)
  --assignee-id: string # The `id` of the `admin` or `team` which will be assigned the conversation. A conversation can be assigned both an admin and a team.\nSet `0` if you want this assign to no admin or team (ie. Unassigned). (e.g. 4324241)
]: any -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/parts")
  let body = {message_type: $message_type, type: $type, admin_id: $admin_id, body: $body_body, snoozed_until: $snoozed_until, assignee_id: $assignee_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Assignment Rules on a conversation
#
# POST /conversations/{conversation_id}/run_assignment_rules
# operationId: autoAssignConversation
export def "conversations-run-assignment-rules autoAssignConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/run_assignment_rules")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a contact to a conversation
#
# POST /conversations/{conversation_id}/customers
# operationId: attachContactToConversation
# --customer shape: {intercom_user_id?: string, customer?: record, user_id?: string, email?: string}
export def "conversations-customers attachContactToConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --admin-id: string # The `id` of the admin who is adding the new participant. (e.g. 12345)
  --customer: record # shape: {intercom_user_id?: string, customer?: record, user_id?: string, email?: string}
]: any -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/customers")
  let body = {admin_id: $admin_id, customer: $customer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Detach a contact from a group conversation
#
# DELETE /conversations/{conversation_id}/customers/{contact_id}
# operationId: detachContactFromConversation
export def "conversations-customers detachContactFromConversation" [
  conversation_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  admin_id: string # The `id` of the admin who is performing the action. (e.g. 5017690)
]: any -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/customers/($contact_id)")
  let body = {admin_id: $admin_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Redact a conversation part
#
# POST /conversations/redact
# operationId: redactConversation
export def "conversations-redact redactConversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --type: string@type-completer-1 # The type of resource being redacted. (e.g. conversation_part)
  --conversation-id: string # The id of the conversation. (e.g. 19894788788)
  --conversation-part-id: string # The id of the conversation_part. (e.g. 19381789428)
  --source-id: string # The id of the source. (e.g. 19894781231)
]: any -> record<type: string, id: string, title: string, created_at: int, updated_at: int, waiting_since: int, snoozed_until: int, open: bool, state: string, read: bool, priority: string, admin_assignee_id: int, team_assignee_id: int, tags: record<type: string, tags: list<record>>, conversation_rating: record<rating: int, remark: string, created_at: int, contact: record<type: string, id: string, external_id: string>, teammate: record<type: string, id: string>>, source: record<type: string, id: string, delivered_as: string, subject: string, body: string, author: record<type: string, id: string, name: string, email: string>, attachments: list<record>, url: string, redacted: bool>, contacts: record<type: string, contacts: list<record>>, teammates: record<type: string, teammates: list<record>>, custom_attributes: any, first_contact_reply: record<created_at: int, type: string, url: string>, sla_applied: record<type: string, sla_name: string, sla_status: string>, statistics: record<type: string, time_to_assignment: int, time_to_admin_reply: int, time_to_first_close: int, time_to_last_close: int, median_time_to_reply: int, first_contact_reply_at: int, first_assignment_at: int, first_admin_reply_at: int, first_close_at: int, last_assignment_at: int, last_assignment_admin_reply_at: int, last_contact_reply_at: int, last_admin_reply_at: int, last_close_at: int, last_closed_by_id: string, count_reopens: int, count_assignments: int, count_conversation_parts: int>, conversation_parts: record<type: string, conversation_parts: list<record>, total_count: int>, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ai_agent_participated: bool, ai_agent: record<source_type: string, source_title: string, last_answer_type: string, resolution_state: string, rating: int, rating_remark: string, content_sources: record<type: string, total_count: int, content_sources: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/redact")
  let body = {type: $type, conversation_id: $conversation_id, conversation_part_id: $conversation_part_id, source_id: $source_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Convert a conversation to a ticket
#
# POST /conversations/{conversation_id}/convert
# operationId: convertConversationToTicket
export def "conversations-convert convertConversationToTicket" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  ticket_type_id: string # The ID of the type of ticket you want to convert the conversation to (e.g. 1234)
  --attributes: record # The attributes set on the ticket. When setting the default title and description attributes, the attribute keys that should be used are `_default_title_` and `_default_description_`. When setting ticket type attributes of the list attribute type, the key should be the attribute name and the value of the attribute should be the list item id, obtainable by [listing the ticket type](ref:get_ticket-types). For example, if the ticket type has an attribute called `priority` of type `list`, the key should be `priority` and the value of the attribute should be the guid of the list item (e.g. `de1825a0-0164-4070-8ca6-13e22462fa7e`). (e.g. {_default_title_: Found a bug, _default_description_: The button is not working})
]: any -> record<type: string, id: string, ticket_id: string, category: string, ticket_attributes: record, ticket_state: string, ticket_type: record<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record<type: string, ticket_type_attributes: list>, archived: bool, created_at: int, updated_at: int>, contacts: record<type: string, contacts: list<record>>, admin_assignee_id: string, team_assignee_id: string, created_at: int, updated_at: int, open: bool, snoozed_until: int, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ticket_parts: record<type: string, ticket_parts: list<record>, total_count: int>, is_shared: bool, ticket_state_internal_label: string, ticket_state_external_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/convert")
  let body = {ticket_type_id: $ticket_type_id, attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all data attributes
#
# GET /data_attributes
# operationId: listDataAttributes
export def "data-attributes listDataAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string@model-completer # Specify the data attribute model to return. (e.g. company)
  --include-archived: oneof<nothing, bool> # Include archived attributes in the list. By default we return only non archived data attributes. (e.g. false)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: int, model: string, name: string, full_name: string, label: string, description: string, data_type: string, options: list, api_writable: bool, messenger_writable: bool, ui_writable: bool, custom: bool, archived: bool, created_at: int, updated_at: int, admin_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data_attributes" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a data attribute
#
# POST /data_attributes
# operationId: createDataAttribute
export def "data-attributes createDataAttribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  name: string # The name of the data attribute. (e.g. My Data Attribute)
  model: string@model-completer-1 # The model that the data attribute belongs to. (e.g. contact)
  data_type: string@data-type-completer # The type of data stored for this attribute. (e.g. string)
  --description: string # The readable description you see in the UI for the attribute. (e.g. My Data Attribute Description)
  --options: list # To create list attributes. Provide a set of hashes with `value` as the key of the options you want to make. `data_type` must be `string`. (e.g. [option1, option2])
  --messenger-writable: oneof<nothing, bool> # Can this attribute be updated by the Messenger (e.g. false)
]: any -> record<type: string, id: int, model: string, name: string, full_name: string, label: string, description: string, data_type: string, options: list<string>, api_writable: bool, messenger_writable: bool, ui_writable: bool, custom: bool, archived: bool, created_at: int, updated_at: int, admin_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data_attributes")
  let body = {name: $name, model: $model, data_type: $data_type, description: $description, options: $options, messenger_writable: $messenger_writable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a data attribute
#
# PUT /data_attributes/{data_attribute_id}
# operationId: updateDataAttribute
# --options item shape: {value: string}
export def "data-attributes updateDataAttribute" [
  data_attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --archived: oneof<nothing, bool> # Whether the attribute is to be archived or not. (e.g. false)
  --description: string # The readable description you see in the UI for the attribute. (e.g. My Data Attribute Description)
  --options: list # To create list attributes. Provide a set of hashes with `value` as the key of the options you want to make. `data_type` must be `string`. (e.g. [option1, option2]) — item shape: {value: string}
  --messenger-writable: oneof<nothing, bool> # Can this attribute be updated by the Messenger (e.g. false)
]: any -> record<type: string, id: int, model: string, name: string, full_name: string, label: string, description: string, data_type: string, options: list<string>, api_writable: bool, messenger_writable: bool, ui_writable: bool, custom: bool, archived: bool, created_at: int, updated_at: int, admin_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data_attributes/($data_attribute_id)")
  let body = {archived: $archived, description: $description, options: $options, messenger_writable: $messenger_writable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit a data event
#
# POST /events
# operationId: createDataEvent
export def "events createDataEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --event-name: string # The name of the event that occurred. This is presented to your App's admins when filtering and creating segments - a good event name is typically a past tense 'verb-noun' combination, to improve readability, for example `updated-plan`. (e.g. invited-friend)
  --created-at: int # The time the event occurred as a UTC Unix timestamp (format: date-time, e.g. 1671028894)
  --user-id: string # Your identifier for the user. (e.g. 314159)
  --id: string # The unique identifier for the contact (lead or user) which is given by Intercom. (e.g. 8a88a590-e1c3-41e2-a502-e0649dbf721c)
  --email: string # An email address for your user. An email should only be used where your application uses email to uniquely identify users. (e.g. frodo.baggins@example.com)
  --metadata: record # Optional metadata about the event. (e.g. {invite_code: ADDAFRIEND})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events")
  let body = {event_name: $event_name, created_at: $created_at, user_id: $user_id, id: $id, email: $email, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all data events
#
# GET /events
# operationId: lisDataEvents
export def "events lisDataEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record
  --type: string # The value must be user
  --summary: oneof<nothing, bool> # summary flag
  --per-page: int # How many results to display per page. Defaults to 15 (e.g. 15)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, email: string, intercom_user_id: string, user_id: string, events: table<name: string, first: string, last: string, count: int, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "multi") (serialize-qp "type" $type "scalar") (serialize-qp "summary" $summary "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create event summaries
#
# POST /events/summaries
# operationId: dataEventSummaries
# --event_summaries shape: {event_name?: string, count?: int, first?: int, last?: int}
export def "events-summaries dataEventSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --user-id: string # Your identifier for the user. (e.g. 314159)
  --event-summaries: record # A list of event summaries for the user. Each event summary should contain the event name, the time the event occurred, and the number of times the event occurred. The event name should be a past tense 'verb-noun' combination, to improve readability, for example `updated-plan`. — shape: {event_name?: string, count?: int, first?: int, last?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/summaries")
  let body = {user_id: $user_id, event_summaries: $event_summaries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create content data export
#
# POST /export/content/data
# operationId: createDataExport
export def "export-content-data createDataExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  created_at_after: int # The start date that you request data for. It must be formatted as a unix timestamp. (e.g. 1527811200)
  created_at_before: int # The end date that you request data for. It must be formatted as a unix timestamp. (e.g. 1527811200)
]: any -> record<job_identifier: string, status: string, download_expires_at: string, download_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/content/data")
  let body = {created_at_after: $created_at_after, created_at_before: $created_at_before} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show content data export
#
# GET /export/content/data/{job_identifier}
# operationId: getDataExport
export def "export-content-data get" [
  job_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<job_identifier: string, status: string, download_expires_at: string, download_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/export/content/data/($job_identifier)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel content data export
#
# POST /export/cancel/{job_identifier}
# operationId: cancelDataExport
export def "export-cancel cancelDataExport" [
  job_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<job_identifier: string, status: string, download_expires_at: string, download_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/export/cancel/($job_identifier)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download content data export
#
# GET /download/content/data/{job_identifier}
# operationId: downloadDataExport
export def "download-content-data downloadDataExport" [
  job_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/download/content/data/($job_identifier)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a message
#
# POST /messages
# operationId: createMessage
# --from shape: {type: "lead"|"user"|"contact"|"admin", id: int}
# --to shape: {type: "user"|"lead", id: string}
export def "messages createMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --message-type: string@message-type-completer-2 # The kind of message being created. Values: `in_app` or `email`. (e.g. in_app)
  --subject: string # The title of the email. (e.g. Thanks for everything)
  --body-body: string # The content of the message. HTML and plaintext are supported. (e.g. Hello there)
  --template: string # The style of the outgoing message. Possible values `plain` or `personal`. (e.g. plain)
  --body-from: record # The sender of the message. If not provided, the default sender will be used. — shape: {type: "lead"|"user"|"contact"|"admin", id: int}
  --body-to: record # The recipient of the message. If not provided, the default recipient will be used. — shape: {type: "user"|"lead", id: string}
  --created-at: int # The time the message was created. If not provided, the current time will be used. (e.g. 1590000000)
  --create-conversation-without-contact-reply: oneof<nothing, bool> # Whether a conversation should be opened in the inbox for the message without the contact replying. Defaults to false if not provided. (default: false, e.g. true)
]: any -> record<type: string, id: string, created_at: int, subject: string, body: string, message_type: string, conversation_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages")
  let body = {message_type: $message_type, subject: $subject, body: $body_body, template: $template, from: $body_from, to: $body_to, created_at: $created_at, create_conversation_without_contact_reply: $create_conversation_without_contact_reply} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all news items
#
# GET /news/news_items
# operationId: listNewsItems
export def "news-news-items listNewsItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, data: table<type: string, id: string, workspace_id: string, title: string, body: string, sender_id: int, state: string, newsfeed_assignments: list, labels: list, cover_image_url: string, reactions: list, deliver_silently: bool, created_at: int, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/news/news_items")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a news item
#
# POST /news/news_items
# operationId: createNewsItem
# --newsfeed_assignments item shape: {newsfeed_id: int, published_at: int}
export def "news-news-items createNewsItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  title: string # The title of the news item. (e.g. Halloween is here!)
  --body-body: string # The news item body, which may contain HTML. (e.g. <p>New costumes in store for this spooky season</p>)
  sender_id: int # The id of the sender of the news item. Must be a teammate on the workspace. (e.g. 123)
  --state: string@state-completer-1 # News items will not be visible to your users in the assigned newsfeeds until they are set live. (e.g. live)
  --deliver-silently: oneof<nothing, bool> # When set to `true`, the news item will appear in the messenger newsfeed without showing a notification badge. (e.g. true)
  --labels: list # Label names displayed to users to categorize the news item. (e.g. [Product, Update, New])
  --reactions: list # Ordered list of emoji reactions to the news item. When empty, reactions are disabled. (e.g. [😆, 😅])
  --newsfeed-assignments: list # A list of newsfeed_assignments to assign to the specified newsfeed. — item shape: {newsfeed_id: int, published_at: int}
]: any -> record<type: string, id: string, workspace_id: string, title: string, body: string, sender_id: int, state: string, newsfeed_assignments: table<newsfeed_id: int, published_at: int>, labels: list<string>, cover_image_url: string, reactions: list<string>, deliver_silently: bool, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/news/news_items")
  let body = {title: $title, body: $body_body, sender_id: $sender_id, state: $state, deliver_silently: $deliver_silently, labels: $labels, reactions: $reactions, newsfeed_assignments: $newsfeed_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a news item
#
# GET /news/news_items/{news_item_id}
# operationId: retrieveNewsItem
export def "news-news-items retrieveNewsItem" [
  news_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, workspace_id: string, title: string, body: string, sender_id: int, state: string, newsfeed_assignments: table<newsfeed_id: int, published_at: int>, labels: list<string>, cover_image_url: string, reactions: list<string>, deliver_silently: bool, created_at: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/news/news_items/($news_item_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a news item
#
# PUT /news/news_items/{news_item_id}
# operationId: updateNewsItem
# --newsfeed_assignments item shape: {newsfeed_id: int, published_at: int}
export def "news-news-items updateNewsItem" [
  news_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  title: string # The title of the news item. (e.g. Halloween is here!)
  --body-body: string # The news item body, which may contain HTML. (e.g. <p>New costumes in store for this spooky season</p>)
  sender_id: int # The id of the sender of the news item. Must be a teammate on the workspace. (e.g. 123)
  --state: string@state-completer-1 # News items will not be visible to your users in the assigned newsfeeds until they are set live. (e.g. live)
  --deliver-silently: oneof<nothing, bool> # When set to `true`, the news item will appear in the messenger newsfeed without showing a notification badge. (e.g. true)
  --labels: list # Label names displayed to users to categorize the news item. (e.g. [Product, Update, New])
  --reactions: list # Ordered list of emoji reactions to the news item. When empty, reactions are disabled. (e.g. [😆, 😅])
  --newsfeed-assignments: list # A list of newsfeed_assignments to assign to the specified newsfeed. — item shape: {newsfeed_id: int, published_at: int}
]: any -> record<type: string, id: string, workspace_id: string, title: string, body: string, sender_id: int, state: string, newsfeed_assignments: table<newsfeed_id: int, published_at: int>, labels: list<string>, cover_image_url: string, reactions: list<string>, deliver_silently: bool, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/news/news_items/($news_item_id)")
  let body = {title: $title, body: $body_body, sender_id: $sender_id, state: $state, deliver_silently: $deliver_silently, labels: $labels, reactions: $reactions, newsfeed_assignments: $newsfeed_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a news item
#
# DELETE /news/news_items/{news_item_id}
# operationId: deleteNewsItem
export def "news-news-items delete" [
  news_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/news/news_items/($news_item_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all live newsfeed items
#
# GET /news/newsfeeds/{newsfeed_id}/items
# operationId: listLiveNewsfeedItems
export def "news-newsfeeds-items listLiveNewsfeedItems" [
  newsfeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, data: table<type: string, id: string, workspace_id: string, title: string, body: string, sender_id: int, state: string, newsfeed_assignments: list, labels: list, cover_image_url: string, reactions: list, deliver_silently: bool, created_at: int, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/news/newsfeeds/($newsfeed_id)/items")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all newsfeeds
#
# GET /news/newsfeeds
# operationId: listNewsfeeds
export def "news-newsfeeds listNewsfeeds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>, total_count: int, data: table<id: string, type: string, name: string, created_at: int, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/news/newsfeeds")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a newsfeed
#
# GET /news/newsfeeds/{newsfeed_id}
# operationId: retrieveNewsfeed
export def "news-newsfeeds retrieveNewsfeed" [
  newsfeed_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<id: string, type: string, name: string, created_at: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/news/newsfeeds/($newsfeed_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a note
#
# GET /notes/{note_id}
# operationId: retrieveNote
export def "notes retrieveNote" [
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, created_at: int, contact: record<type: string, id: string>, author: record<type: string, id: string, name: string, email: string, job_title: string, away_mode_enabled: bool, away_mode_reassign: bool, has_inbox_seat: bool, team_ids: list<int>, avatar: record<image_url: string>, team_priority_level: record<primary_team_ids: list, secondary_team_ids: list>>, body: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notes/($note_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all segments
#
# GET /segments
# operationId: listSegments
export def "segments listSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-count: oneof<nothing, bool> # It includes the count of contacts that belong to each segment. (e.g. true)
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, segments: table<type: string, id: string, name: string, created_at: int, updated_at: int, person_type: string, count: int>, pages: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_count" $include_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/segments" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a segment
#
# GET /segments/{segment_id}
# operationId: retrieveSegment
export def "segments retrieveSegment" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, created_at: int, updated_at: int, person_type: string, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/segments/($segment_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List subscription types
#
# GET /subscription_types
# operationId: listSubscriptionTypes
export def "subscription-types listSubscriptionTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, state: string, default_translation: record, translations: list, consent_type: string, content_types: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription_types")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a phone Switch
#
# POST /phone_call_redirects
# operationId: createPhoneSwitch
export def "phone-call-redirects createPhoneSwitch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  phone: string # Phone number in E.164 format, that will receive the SMS to continue the conversation in the Messenger. (e.g. +1 1234567890)
  --custom-attributes: any
]: any -> record<type: string, phone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_call_redirects")
  let body = {phone: $phone, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all tags
#
# GET /tags
# operationId: listTags
export def "tags listTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, data: table<type: string, id: string, name: string, applied_at: int, applied_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a tag, Tag or untag companies, Tag contacts
#
# POST /tags
# operationId: createTag
# --companies item shape: {id?: string, company_id?: string}
# --users item shape: {id?: string}
export def "tags createTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --name: string # The name of the tag, which will be created if not found, or the new name for the tag if this is an update request. Names are case insensitive. (e.g. Independent)
  --id: string # The id of tag to updates. (e.g. 656452352)
  --companies: list # The id or company_id of the company can be passed as input parameters. — item shape: {id?: string, company_id?: string}
  --users: list # item shape: {id?: string}
]: any -> record<type: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {name: $name, id: $id, companies: $companies, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find a specific tag
#
# GET /tags/{tag_id}
# operationId: findTag
export def "tags findTag" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete tag
#
# DELETE /tags/{tag_id}
# operationId: deleteTag
export def "tags delete" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tag_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all teams
#
# GET /teams
# operationId: listTeams
export def "teams listTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, teams: table<type: string, id: string, name: string, admin_ids: list, admin_priority_level: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teams")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a team
#
# GET /teams/{team_id}
# operationId: retrieveTeam
export def "teams retrieveTeam" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, name: string, admin_ids: list<int>, admin_priority_level: record<primary_admin_ids: list<int>, secondary_admin_ids: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new attribute for a ticket type
#
# POST /ticket_types/{ticket_type_id}/attributes
# operationId: createTicketTypeAttribute
export def "ticket-types-attributes createTicketTypeAttribute" [
  ticket_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  name: string # The name of the ticket type attribute (e.g. Bug Priority)
  description: string # The description of the attribute presented to the teammate or contact (e.g. Priority level of the bug)
  data_type: string@data-type-completer-1 # The data type of the attribute (e.g. string)
  --required-to-create: oneof<nothing, bool> # Whether the attribute is required to be filled in when teammates are creating the ticket in Inbox. (default: false, e.g. false)
  --required-to-create-for-contacts: oneof<nothing, bool> # Whether the attribute is required to be filled in when contacts are creating the ticket in Messenger. (default: false, e.g. false)
  --visible-on-create: oneof<nothing, bool> # Whether the attribute is visible to teammates when creating a ticket in Inbox. (default: true, e.g. true)
  --visible-to-contacts: oneof<nothing, bool> # Whether the attribute is visible to contacts when creating a ticket in Messenger. (default: true, e.g. true)
  --multiline: oneof<nothing, bool> # Whether the attribute allows multiple lines of text (only applicable to string attributes) (e.g. false)
  --list-items: string # A comma delimited list of items for the attribute value (only applicable to list attributes) (e.g. Low Priority,Medium Priority,High Priority)
  --allow-multiple-values: oneof<nothing, bool> # Whether the attribute allows multiple files to be attached to it (only applicable to file attributes) (e.g. false)
]: any -> record<type: string, id: string, workspace_id: string, name: string, description: string, data_type: string, input_options: record, order: int, required_to_create: bool, required_to_create_for_contacts: bool, visible_on_create: bool, visible_to_contacts: bool, default: bool, ticket_type_id: int, archived: bool, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ticket_types/($ticket_type_id)/attributes")
  let body = {name: $name, description: $description, data_type: $data_type, required_to_create: $required_to_create, required_to_create_for_contacts: $required_to_create_for_contacts, visible_on_create: $visible_on_create, visible_to_contacts: $visible_to_contacts, multiline: $multiline, list_items: $list_items, allow_multiple_values: $allow_multiple_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an existing attribute for a ticket type
#
# PUT /ticket_types/{ticket_type_id}/attributes/{attribute_id}
# operationId: updateTicketTypeAttribute
export def "ticket-types-attributes updateTicketTypeAttribute" [
  ticket_type_id: string
  attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --name: string # The name of the ticket type attribute (e.g. Bug Priority)
  --description: string # The description of the attribute presented to the teammate or contact (e.g. Priority level of the bug)
  --required-to-create: oneof<nothing, bool> # Whether the attribute is required to be filled in when teammates are creating the ticket in Inbox. (default: false, e.g. false)
  --required-to-create-for-contacts: oneof<nothing, bool> # Whether the attribute is required to be filled in when contacts are creating the ticket in Messenger. (default: false, e.g. false)
  --visible-on-create: oneof<nothing, bool> # Whether the attribute is visible to teammates when creating a ticket in Inbox. (default: true, e.g. true)
  --visible-to-contacts: oneof<nothing, bool> # Whether the attribute is visible to contacts when creating a ticket in Messenger. (default: true, e.g. true)
  --multiline: oneof<nothing, bool> # Whether the attribute allows multiple lines of text (only applicable to string attributes) (e.g. false)
  --list-items: string # A comma delimited list of items for the attribute value (only applicable to list attributes) (e.g. Low Priority,Medium Priority,High Priority)
  --allow-multiple-values: oneof<nothing, bool> # Whether the attribute allows multiple files to be attached to it (only applicable to file attributes) (e.g. false)
  --archived: oneof<nothing, bool> # Whether the attribute should be archived and not shown during creation of the ticket (it will still be present on previously created tickets) (e.g. false)
]: any -> record<type: string, id: string, workspace_id: string, name: string, description: string, data_type: string, input_options: record, order: int, required_to_create: bool, required_to_create_for_contacts: bool, visible_on_create: bool, visible_to_contacts: bool, default: bool, ticket_type_id: int, archived: bool, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ticket_types/($ticket_type_id)/attributes/($attribute_id)")
  let body = {name: $name, description: $description, required_to_create: $required_to_create, required_to_create_for_contacts: $required_to_create_for_contacts, visible_on_create: $visible_on_create, visible_to_contacts: $visible_to_contacts, multiline: $multiline, list_items: $list_items, allow_multiple_values: $allow_multiple_values, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all ticket types
#
# GET /ticket_types
# operationId: listTicketTypes
export def "ticket-types listTicketTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, ticket_types: table<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record, archived: bool, created_at: int, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ticket_types")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ticket type
#
# POST /ticket_types
# operationId: createTicketType
export def "ticket-types createTicketType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  name: string # The name of the ticket type. (e.g. Bug)
  --description: string # The description of the ticket type. (e.g. Used for tracking bugs)
  --category: string@category-completer # Category of the Ticket Type. (e.g. Customer)
  --icon: string # The icon of the ticket type. (default: 🎟️, e.g. 🐞)
  --is-internal: oneof<nothing, bool> # Whether the tickets associated with this ticket type are intended for internal use only or will be shared with customers. This is currently a limited attribute. (default: false, e.g. false)
]: any -> record<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record<type: string, ticket_type_attributes: list<record>>, archived: bool, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ticket_types")
  let body = {name: $name, description: $description, category: $category, icon: $icon, is_internal: $is_internal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a ticket type
#
# GET /ticket_types/{ticket_type_id}
# operationId: getTicketType
export def "ticket-types get" [
  ticket_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record<type: string, ticket_type_attributes: list<record>>, archived: bool, created_at: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ticket_types/($ticket_type_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a ticket type
#
# PUT /ticket_types/{ticket_type_id}
# operationId: updateTicketType
export def "ticket-types updateTicketType" [
  ticket_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --name: string # The name of the ticket type. (e.g. Bug)
  --description: string # The description of the ticket type. (e.g. A bug has been occured)
  --category: string@category-completer # Category of the Ticket Type. (e.g. Customer)
  --icon: string # The icon of the ticket type. (default: 🎟️, e.g. 🐞)
  --archived: oneof<nothing, bool> # The archived status of the ticket type. (e.g. false)
  --is-internal: oneof<nothing, bool> # Whether the tickets associated with this ticket type are intended for internal use only or will be shared with customers. This is currently a limited attribute. (default: false, e.g. false)
]: any -> record<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record<type: string, ticket_type_attributes: list<record>>, archived: bool, created_at: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ticket_types/($ticket_type_id)")
  let body = {name: $name, description: $description, category: $category, icon: $icon, archived: $archived, is_internal: $is_internal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reply to a ticket
#
# POST /tickets/{ticket_id}/reply
# operationId: replyTicket
# --reply_options item shape: {text: string, uuid: string}
export def "tickets-reply replyTicket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --message-type: string@message-type-completer-3 # e.g. comment
  --type: string@type-completer # e.g. admin
  --body-body: string # The text body of the reply. Notes accept some HTML formatting. Must be present for comment and note message types. (e.g. Hello there!)
  --admin-id: string # The id of the admin who is authoring the comment. (e.g. 3156780)
  --created-at: int # The time the reply was created. If not provided, the current time will be used. (e.g. 1590000000)
  --reply-options: list # The quick reply options to display. Must be present for quick_reply message types. — item shape: {text: string, uuid: string}
  --attachment-urls: list # A list of image URLs that will be added as attachments. You can include up to 10 URLs.
  --cross-post: oneof<nothing, bool> # If set to true, the note will be cross-posted to all linked conversations. Only applicable to note message types on back-office tickets. (e.g. true)
]: any -> record<type: string, id: string, part_type: string, body: string, created_at: int, updated_at: int, author: record<type: string, id: string, name: string, email: string>, attachments: table<type: string, name: string, url: string, content_type: string, filesize: int, width: int, height: int>, redacted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tickets/($ticket_id)/reply")
  let body = {message_type: $message_type, type: $type, body: $body_body, admin_id: $admin_id, created_at: $created_at, reply_options: $reply_options, attachment_urls: $attachment_urls, cross_post: $cross_post} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add tag to a ticket
#
# POST /tickets/{ticket_id}/tags
# operationId: attachTagToTicket
export def "tickets-tags attachTagToTicket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  id: string # The unique identifier for the tag which is given by Intercom (e.g. 7522907)
  admin_id: string # The unique identifier for the admin which is given by Intercom. (e.g. 780)
]: any -> record<type: string, id: string, name: string, applied_at: int, applied_by: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tickets/($ticket_id)/tags")
  let body = {id: $id, admin_id: $admin_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove tag from a ticket
#
# DELETE /tickets/{ticket_id}/tags/{tag_id}
# operationId: detachTagFromTicket
export def "tickets-tags detachTagFromTicket" [
  ticket_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  admin_id: string # The unique identifier for the admin which is given by Intercom. (e.g. 123)
]: any -> record<type: string, id: string, name: string, applied_at: int, applied_by: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tickets/($ticket_id)/tags/($tag_id)")
  let body = {admin_id: $admin_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a ticket
#
# POST /tickets
# operationId: createTicket
export def "tickets createTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  ticket_type_id: string # The ID of the type of ticket you want to create (e.g. 1234)
  contacts: list # The list of contacts (users or leads) affected by this ticket. Currently only one is allowed (e.g. [{id: 1234}])
  --company-id: string # The ID of the company that the ticket is associated with. The ID that you set upon company creation. (e.g. 1234)
  --created-at: int # The time the ticket was created. If not provided, the current time will be used. (e.g. 1590000000)
  --ticket-attributes: record # The attributes set on the ticket. When setting the default title and description attributes, the attribute keys that should be used are `_default_title_` and `_default_description_`. When setting ticket type attributes of the list attribute type, the key should be the attribute name and the value of the attribute should be the list item id, obtainable by [listing the ticket type](ref:get_ticket-types). For example, if the ticket type has an attribute called `priority` of type `list`, the key should be `priority` and the value of the attribute should be the guid of the list item (e.g. `de1825a0-0164-4070-8ca6-13e22462fa7e`). (e.g. {_default_title_: Found a bug, _default_description_: The button is not working})
]: any -> record<type: string, id: string, ticket_id: string, category: string, ticket_attributes: record, ticket_state: string, ticket_type: record<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record<type: string, ticket_type_attributes: list>, archived: bool, created_at: int, updated_at: int>, contacts: record<type: string, contacts: list<record>>, admin_assignee_id: string, team_assignee_id: string, created_at: int, updated_at: int, open: bool, snoozed_until: int, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ticket_parts: record<type: string, ticket_parts: list<record>, total_count: int>, is_shared: bool, ticket_state_internal_label: string, ticket_state_external_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tickets")
  let body = {ticket_type_id: $ticket_type_id, contacts: $contacts, company_id: $company_id, created_at: $created_at, ticket_attributes: $ticket_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a ticket
#
# PUT /tickets/{ticket_id}
# operationId: updateTicket
# --assignment shape: {admin_id?: string, assignee_id?: string}
export def "tickets updateTicket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --ticket-attributes: record # The attributes set on the ticket. (e.g. {_default_title_: example, _default_description_: having a problem})
  --state: string@state-completer-2 # The state of the ticket. (e.g. submitted)
  --body-open: oneof<nothing, bool> # Specify if a ticket is open. Set to false to close a ticket. Closing a ticket will also unsnooze it. (e.g. true)
  --is-shared: oneof<nothing, bool> # Specify whether the ticket is visible to users. (e.g. true)
  --snoozed-until: int # The time you want the ticket to reopen. (format: timestamp, e.g. 1673609604)
  --assignment: record # shape: {admin_id?: string, assignee_id?: string}
]: any -> record<type: string, id: string, ticket_id: string, category: string, ticket_attributes: record, ticket_state: string, ticket_type: record<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record<type: string, ticket_type_attributes: list>, archived: bool, created_at: int, updated_at: int>, contacts: record<type: string, contacts: list<record>>, admin_assignee_id: string, team_assignee_id: string, created_at: int, updated_at: int, open: bool, snoozed_until: int, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ticket_parts: record<type: string, ticket_parts: list<record>, total_count: int>, is_shared: bool, ticket_state_internal_label: string, ticket_state_external_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tickets/($ticket_id)")
  let body = {ticket_attributes: $ticket_attributes, state: $state, open: $body_open, is_shared: $is_shared, snoozed_until: $snoozed_until, assignment: $assignment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a ticket
#
# GET /tickets/{ticket_id}
# operationId: getTicket
export def "tickets get" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, ticket_id: string, category: string, ticket_attributes: record, ticket_state: string, ticket_type: record<type: string, id: string, category: string, name: string, description: string, icon: string, workspace_id: string, ticket_type_attributes: record<type: string, ticket_type_attributes: list>, archived: bool, created_at: int, updated_at: int>, contacts: record<type: string, contacts: list<record>>, admin_assignee_id: string, team_assignee_id: string, created_at: int, updated_at: int, open: bool, snoozed_until: int, linked_objects: record<type: string, total_count: int, has_more: bool, data: list<record>>, ticket_parts: record<type: string, ticket_parts: list<record>, total_count: int>, is_shared: bool, ticket_state_internal_label: string, ticket_state_external_label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tickets/($ticket_id)")
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search tickets
#
# POST /tickets/search
# operationId: searchTickets
# --pagination shape: {per_page: int, starting_after?: string}
export def "tickets-search searchTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --body-query: any
  --pagination: record # shape: {per_page: int, starting_after?: string}
]: any -> record<type: string, tickets: table<type: string, id: string, ticket_id: string, category: string, ticket_attributes: record, ticket_state: string, ticket_type: record, contacts: record, admin_assignee_id: string, team_assignee_id: string, created_at: int, updated_at: int, open: bool, snoozed_until: int, linked_objects: record, ticket_parts: record, is_shared: bool, ticket_state_internal_label: string, ticket_state_external_label: string>, total_count: int, pages: record<type: string, page: int, next: record<per_page: int, starting_after: string>, per_page: int, total_pages: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tickets/search")
  let body = {query: $body_query, pagination: $pagination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a visitor
#
# PUT /visitors
# operationId: updateVisitor
export def "visitors updateVisitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  --id: string # A unique identified for the visitor which is given by Intercom. (e.g. 8a88a590-e)
  --user-id: string # A unique identified for the visitor which is given by you. (e.g. 123)
  --name: string # The visitor's name. (e.g. Christian Bale)
  --custom-attributes: record # The custom attributes which are set for the visitor. (e.g. {paid_subscriber: true, monthly_spend: 155.5, team_mates: 9})
]: any -> record<type: string, id: string, user_id: string, anonymous: bool, email: string, phone: string, name: string, pseudonym: string, avatar: record<type: string, image_url: string>, app_id: string, companies: record<type: string, companies: list<record>>, location_data: record<type: string, city_name: string, continent_code: string, country_code: string, country_name: string, postal_code: string, region_name: string, timezone: string>, las_request_at: int, created_at: int, remote_created_at: int, signed_up_at: int, updated_at: int, session_count: int, social_profiles: record<type: string, social_profiles: list<string>>, owner_id: string, unsubscribed_from_emails: bool, marked_email_as_spam: bool, has_hard_bounced: bool, tags: record<type: string, tags: list<record>>, segments: record<type: string, segments: list<string>>, custom_attributes: record, referrer: string, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string, do_not_track: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/visitors")
  let body = {id: $id, user_id: $user_id, name: $name, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a visitor with User ID
#
# GET /visitors
# operationId: retrieveVisitorWithUserId
export def "visitors retrieveVisitorWithUserId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The user_id of the Visitor you want to retrieve.
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
]: nothing -> record<type: string, id: string, user_id: string, anonymous: bool, email: string, phone: string, name: string, pseudonym: string, avatar: record<type: string, image_url: string>, app_id: string, companies: record<type: string, companies: list<record>>, location_data: record<type: string, city_name: string, continent_code: string, country_code: string, country_name: string, postal_code: string, region_name: string, timezone: string>, las_request_at: int, created_at: int, remote_created_at: int, signed_up_at: int, updated_at: int, session_count: int, social_profiles: record<type: string, social_profiles: list<string>>, owner_id: string, unsubscribed_from_emails: bool, marked_email_as_spam: bool, has_hard_bounced: bool, tags: record<type: string, tags: list<record>>, segments: record<type: string, segments: list<string>>, custom_attributes: record, referrer: string, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string, do_not_track: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/visitors" $qp)
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Convert a visitor
#
# POST /visitors/convert
# operationId: convertVisitor
# --user shape: {id?: string, user_id?: string, email?: string}
# --visitor shape: {id?: string, user_id?: string, email?: string}
export def "visitors-convert convertVisitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Intercom-Version: string@Intercom-Version-completer # e.g. 2.11
  type: string # Represents the role of the Contact model. Accepts `lead` or `user`. (e.g. user)
  user: record # The unique identifiers retained after converting or merging. — shape: {id?: string, user_id?: string, email?: string}
  visitor: record # The unique identifiers to convert a single Visitor. — shape: {id?: string, user_id?: string, email?: string}
]: any -> record<type: string, id: string, external_id: string, workspace_id: string, role: string, email: string, email_domain: string, phone: string, formatted_phone: string, name: string, owner_id: int, has_hard_bounced: bool, marked_email_as_spam: bool, unsubscribed_from_emails: bool, created_at: int, updated_at: int, signed_up_at: int, last_seen_at: int, last_replied_at: int, last_contacted_at: int, last_email_opened_at: int, last_email_clicked_at: int, language_override: string, browser: string, browser_version: string, browser_language: string, os: string, android_app_name: string, android_app_version: string, android_device: string, android_os_version: string, android_sdk_version: string, android_last_seen_at: int, ios_app_name: string, ios_app_version: string, ios_device: string, ios_os_version: string, ios_sdk_version: string, ios_last_seen_at: int, custom_attributes: record, avatar: record<type: string, image_url: string>, tags: record<data: list<record>, url: string, total_count: int, has_more: bool>, notes: record<data: list<record>, url: string, total_count: int, has_more: bool>, companies: record<type: string, data: list<record>, url: string, total_count: int, has_more: bool>, location: record<type: string, country: string, region: string, city: string>, social_profiles: record<data: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/visitors/convert")
  let body = {type: $type, user: $user, visitor: $visitor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Intercom-Version": $Intercom_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
