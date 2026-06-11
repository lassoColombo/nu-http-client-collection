# Auto-generated client for Tuleap API v17.5.99.1781099705-1
# Source: https://tuleap.net/api/explorer/swagger.json
# Auth: --token flag or $env.TULEAP_API_TOKEN

const BASE_URL = "https://tuleap.net/api"
const DEFAULT_AUTH = "x-auth-accesskey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TULEAP_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-auth-accesskey" => { {headers: {X-Auth-AccessKey: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://tuleap.net/api"] }
def auth-scheme-completer [] { ["x-auth-accesskey" "bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def status-completer [] { ["active" "suspended"] }
def identifier-completer [] { ["aerial-water" "asphalt-rock" "beach-daytime" "blue-rain" "blue-sand" "brown-alpaca" "brown-desert" "brown-grass" "brown-textile" "brush-daytime" "green-grass" "green-leaf" "green-trees" "led-light" "ocean-waves" "octopus-black" "orange-tulip" "purple-building" "purple-droplet" "purple-textile" "snow-mountain" "tree-water" "white-sheep" "wooden-surface"] }
def fields-completer [] { ["all" "basic"] }
def order-by-completer [] { ["path" "push_date"] }
def representation-completer [] { ["full" "minimal"] }
def fields-completer-1 [] { ["all" "slim"] }
def order-completer [] { ["asc" "desc"] }
def scope-completer [] { ["project"] }
def format-completer [] { ["full" "id"] }
def query-completer [] { ["with_ssh_key"] }
def status-completer-1 [] { ["done" "error" "new" "running" "warning"] }
def importance-completer [] { ["critical" "standard" "warning"] }
def status-completer-2 [] { ["closed" "disabled" "enabled"] }
def notification-type-completer [] { ["all_at_once" "disabled" "sequential"] }
def action-completer [] { ["copy" "empty" "reset"] }
def review-completer [] { ["approved" "comment_only" "not_yet" "rejected" "will_not_review"] }
def approval-table-action-completer [] { ["copy" "empty" "reset"] }
def status-completer-3 [] { ["approved" "draft" "none" "rejected"] }
def disconnect-from-gerrit-completer [] { ["delete" "noop" "read-only"] }
def state-completer [] { ["failure" "pending" "success"] }
def format-completer-1 [] { ["full" "minimal"] }
def values-completer [] { ["" "all"] }
def values-format-completer [] { ["" "all" "by_field" "collection"] }
def tracker-structure-format-completer [] { ["" "complete" "minimal"] }
def direction-completer [] { ["forward" "reverse"] }
def output-format-completer [] { ["flat" "flat_with_semicolon_string_array" "nested"] }
def fields-completer-2 [] { ["all" "comments"] }
def values-completer-1 [] { ["" "all" "from_table_renderer"] }
def format-completer-2 [] { ["commonmark" "text"] }
def status-completer-4 [] { ["active" "hidden"] }
def change-status-completer [] { ["closed" "open"] }
def definition-format-completer [] { ["full" "minimal"] }
def test-selector-completer [] { ["all" "milestone" "none" "report"] }
def status-completer-5 [] { ["blocked" "failed" "notrun" "passed"] }
def dashboard-type-completer [] { ["user"] }
def predefined-time-period-completer [] { ["current_week" "last_7_days" "last_month" "last_week" "today" "yesterday"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects createTuleapProjectRESTv1ProjectResource" } } | get name | first)
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

# Creates a new Project 🔐
#
# POST /projects
# operationId: create\Tuleap\Project\REST\v1\ProjectResource
# --from_archive shape: {file_name: string, file_size: int}
export def "projects createTuleapProjectRESTv1ProjectResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --dry-run: string@bool-completer
  shortname: string # Name of the project
  --description: string # Full description of the project
  label: string # LA short description of the project
  --is-public: string@bool-completer # Define the visibility of the project
  --allow-restricted: string@bool-completer # | null Define if the project should accept restricted users
  --template-id: int # Template for this project. (format: int64)
  --xml-template-name: string # Template name provided by the platform
  --categories: list # Categories to be set a project creation
  --body-fields: list # Custom fields to be set a project creation
  --from-archive: any # shape: {file_name: string, file_size: int}
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dry_run" $dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let body = {shortname: $shortname, description: $description, label: $label, is_public: $is_public, allow_restricted: $allow_restricted, template_id: $template_id, xml_template_name: $xml_template_name, categories: $categories, fields: $body_fields, from_archive: $from_archive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get projects ◑
#
# GET /projects
# operationId: retrieve\Tuleap\Project\REST\v1\ProjectResource
export def "projects retrieveTuleapProjectRESTv1ProjectResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --qp-query: string # JSON object of search criteria properties
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project ◑
#
# GET /projects/{id}
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveId
export def "projects TuleapProjectRESTv1ProjectResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project partial update ◑
#
# PATCH /projects/{id}
# operationId: \Tuleap\Project\REST\v1\ProjectResourceModifyProject
export def "projects TuleapProjectRESTv1ProjectResourceModifyProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  status: string@status-completer # status to apply
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get heartbeats ◑
#
# GET /projects/{id}/heartbeats
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveHeartbeats
export def "projects-heartbeats TuleapProjectRESTv1ProjectResourceRetrieveHeartbeats" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/heartbeats")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get labels ◑
#
# GET /projects/{id}/labels
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveLabels
export def "projects-labels TuleapProjectRESTv1ProjectResourceRetrieveLabels" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # Search particular label, if not used, returns all project labels
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/labels" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user_groups ◑
#
# GET /projects/{id}/user_groups
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveUserGroups
export def "projects-user-groups TuleapProjectRESTv1ProjectResourceRetrieveUserGroups" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of filtering options
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/user_groups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get svn ◑
#
# GET /projects/{id}/svn
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveSvn
export def "projects-svn TuleapProjectRESTv1ProjectResourceRetrieveSvn" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # Optional search string in json format
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/svn" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Put banner 🔐
#
# PUT /projects/{id}/banner
# operationId: \Tuleap\Project\REST\v1\ProjectResourceUpdateBanner
export def "projects-banner TuleapProjectRESTv1ProjectResourceUpdateBanner" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  message: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/banner")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the banner message 🔐
#
# DELETE /projects/{id}/banner
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRemoveBanner
export def "projects-banner TuleapProjectRESTv1ProjectResourceRemoveBanner" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/banner")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get banner ◑
#
# GET /projects/{id}/banner
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveBanner
export def "projects-banner TuleapProjectRESTv1ProjectResourceRetrieveBanner" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/banner")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Put a header background to the project 🔐
#
# PUT /projects/{id}/header_background
# operationId: \Tuleap\Project\REST\v1\ProjectResourceUpdateBackgroundHeader
export def "projects-header-background TuleapProjectRESTv1ProjectResourceUpdateBackgroundHeader" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  identifier: string@identifier-completer
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/header_background")
  let body = {identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the header background 🔐
#
# DELETE /projects/{id}/header_background
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRemoveHeaderBackground
export def "projects-header-background TuleapProjectRESTv1ProjectResourceRemoveHeaderBackground" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/header_background")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get PhpWiki pages ◑
#
# GET /projects/{id}/phpwiki
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrievePhpWiki
export def "projects-phpwiki TuleapProjectRESTv1ProjectResourceRetrievePhpWiki" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --pagename: string # Part of the pagename or the full pagename to search
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pagename" $pagename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/phpwiki" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get services ◑
#
# GET /projects/{id}/project_services
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveServices
export def "projects-project-services TuleapProjectRESTv1ProjectResourceRetrieveServices" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/project_services" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract references ◑
#
# POST /projects/{id}/extract_references
# operationId: \Tuleap\Project\REST\v1\ProjectResourceExtractReferences
export def "projects-extract-references TuleapProjectRESTv1ProjectResourceExtractReferences" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  text: string # the text to add Tuleap references
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/extract_references")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get data needed for third party integration ◑
#
# GET /projects/{id}/3rd_party_integration_data
# operationId: \Tuleap\Project\REST\v1\ProjectResourceRetrieveThirdPartyIntegrationData
export def "projects-3rd-party-integration-data TuleapProjectRESTv1ProjectResourceRetrieveThirdPartyIntegrationData" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --currently-active-service: string # The currently active service name
]: nothing -> record<project_sidebar: record<is_collapsed: bool, config: string>, styles: record<content: string, variant_name: string, should_display_favicon_variant: bool>, references: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currently_active_service" $currently_active_service "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/3rd_party_integration_data" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get docman metadata ◑
#
# GET /projects/{id}/docman_metadata
# operationId: tuleap\Docman\REST\v1\ProjectMetadataResourceRetrieveDocmanMetadata
export def "projects-docman-metadata tuleapDocmanRESTv1ProjectMetadataResourceRetrieveDocmanMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/docman_metadata" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get document manager service ◑
#
# GET /projects/{id}/docman_service
# operationId: tuleap\Docman\REST\v1\Service\DocmanServiceResourceRetrieveService
export def "projects-docman-service tuleapDocmanRESTv1ServiceDocmanServiceResourceRetrieveService" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<permissions_for_groups: record<can_admin: list<any>>, root_item: record<id: int, title: string, description: string, post_processed_description: string, owner: string, last_update_date: string, creation_date: string, user_can_write: bool, user_can_delete: bool, type: string, file_properties: string, embedded_file_properties: string, link_properties: string, wiki_properties: string, parent_id: int, is_expanded: bool, can_user_manage: bool, lock_info: string, metadata: list<any>, has_approval_table: bool, is_approval_table_enabled: bool, approval_table: string, permissions_for_groups: record<can_read: list, can_write: list, can_manage: list>, folder_properties: string, other_type_properties: string, item_icon: string, move_uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/docman_service")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get git ◑
#
# GET /projects/{id}/git
# operationId: tuleap\Git\REST\v1\GitProjectResourceRetrieveGit
export def "projects-git tuleapGitRESTv1GitProjectResourceRetrieveGit" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --qp-fields: string@fields-completer # Whether you want to fetch permissions or just repository info (default: basic)
  --qp-query: string # Filter repositories
  --order-by: string@order-by-completer # default: push_date
]: nothing -> record<repositories: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/git" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trackers ◑
#
# GET /projects/{id}/trackers
# operationId: tuleap\Tracker\REST\v1\ProjectTrackersResourceRetrieveTrackers
export def "projects-trackers tuleapTrackerRESTv1ProjectTrackersResourceRetrieveTrackers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --representation: string@representation-completer # Whether you want to fetch full or reference only representations (default: full)
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --qp-query: string # JSON object of search criteria properties
  --with-creation-semantic-check: list # Include the list of reasons why an artifact cannot be created with only the given semantics
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "representation" $representation "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "with_creation_semantic_check" $with_creation_semantic_check "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/trackers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get plannings ◑
#
# GET /projects/{id}/plannings
# operationId: \Tuleap\AgileDashboard\REST\v1\AgileDashboardProjectResourceRetrievePlannings
export def "projects-plannings TuleapAgileDashboardRESTv1AgileDashboardProjectResourceRetrievePlannings" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/plannings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get milestones ◑
#
# GET /projects/{id}/milestones
# operationId: \Tuleap\AgileDashboard\REST\v1\AgileDashboardProjectResourceRetrieveMilestones
export def "projects-milestones TuleapAgileDashboardRESTv1AgileDashboardProjectResourceRetrieveMilestones" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-1 # Set of fields to return in the result (default: all)
  --qp-query: string # JSON object of search criteria properties
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --order: string@order-completer # In which order milestones are fetched. Default is asc (default: asc)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/milestones" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get backlog ◑
#
# GET /projects/{id}/backlog
# operationId: \Tuleap\AgileDashboard\REST\v1\AgileDashboardProjectResourceRetrieveBacklog
export def "projects-backlog TuleapAgileDashboardRESTv1AgileDashboardProjectResourceRetrieveBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/backlog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set order of all backlog items ◑
#
# PUT /projects/{id}/backlog
# operationId: \Tuleap\AgileDashboard\REST\v1\AgileDashboardProjectResourceUpdateBacklog
export def "projects-backlog TuleapAgileDashboardRESTv1AgileDashboardProjectResourceUpdateBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  ids: list # Ids of backlog items
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/backlog")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Re-order backlog items relative to others ◑
#
# PATCH /projects/{id}/backlog
# operationId: \Tuleap\AgileDashboard\REST\v1\AgileDashboardProjectResourceModifyBacklog
# --order shape: {ids: list, direction: string, compared_to: int}
export def "projects-backlog TuleapAgileDashboardRESTv1AgileDashboardProjectResourceModifyBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --order: any # shape: {ids: list, direction: string, compared_to: int}
  --add: list # Add (move) item to the backlog
  --remove: list # Remove item to the backlog
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/backlog")
  let body = {order: $order, add: $add, remove: $remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all Git Jenkins servers that are available in the projects 🔐
#
# GET /projects/{id}/git_jenkins_servers
# operationId: tuleap\HudsonGit\REST\v1\GitJenkinsServersResourceRetrieveGitJenkinsServers
export def "projects-git-jenkins-servers tuleapHudsonGitRESTv1GitJenkinsServersResourceRetrieveGitJenkinsServers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<git_jenkins_servers_representations: list<any>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/git_jenkins_servers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get FRS packages ◑
#
# GET /projects/{id}/frs_packages
# operationId: tuleap\FRS\REST\v1\ProjectResourceRetrieveFRSPackages
export def "projects-frs-packages tuleapFRSRESTv1ProjectResourceRetrieveFRSPackages" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/frs_packages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get File Release System service ◑
#
# GET /projects/{id}/frs_service
# operationId: tuleap\FRS\REST\v1\ProjectResourceRetrieveService
export def "projects-frs-service tuleapFRSRESTv1ProjectResourceRetrieveService" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<permissions_for_groups: record<can_admin: list<any>, can_read: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/frs_service")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Labeled Items ◑
#
# GET /projects/{id}/labeled_items
# operationId: \Tuleap\Label\REST\v1\ProjectResourceRetrieveLabeledItems
export def "projects-labeled-items TuleapLabelRESTv1ProjectResourceRetrieveLabeledItems" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # Search string in json format
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<labeled_items: list<any>, are_there_items_user_cannot_see: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/labeled_items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get campaigns ◑
#
# GET /projects/{id}/testmanagement_campaigns
# operationId: tuleap\TestManagement\REST\v1\ProjectResourceRetrieveCampaigns
export def "projects-testmanagement-campaigns tuleapTestManagementRESTv1ProjectResourceRetrieveCampaigns" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/testmanagement_campaigns" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get test definitions 🔐
#
# GET /projects/{id}/testmanagement_definitions
# operationId: tuleap\TestManagement\REST\v1\ProjectResourceRetrieveDefinitions
export def "projects-testmanagement-definitions tuleapTestManagementRESTv1ProjectResourceRetrieveDefinitions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --report-id: int # Id of the report from which to get the definitions (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "report_id" $report_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/testmanagement_definitions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Mediawiki permissions of the current user ◑
#
# GET /projects/{id}/mediawiki_standalone_permissions
# operationId: tuleap\MediawikiStandalone\REST\v1\MediawikiStandaloneProjectResourceRetrievePermissions
export def "projects-mediawiki-standalone-permissions tuleapMediawikiStandaloneRESTv1MediawikiStandaloneProjectResourceRetrievePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<permissions: record<is_bot: bool, is_reader: bool, is_writer: bool, is_admin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/mediawiki_standalone_permissions")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get baselines ◑
#
# GET /projects/{id}/baselines
# operationId: tuleap\Baseline\REST\ProjectBaselinesResourceRetrieveBaselines
export def "projects-baselines tuleapBaselineRESTProjectBaselinesResourceRetrieveBaselines" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements to fetch (not authorized element are hidden, so you may get less element than requested) (format: int64, default: 10)
  --offset: int # Position of the first element to display (first position is 0). Baselines are sorted by snapshot date (most recent first) (format: int64)
]: nothing -> record<baselines: string, total_count: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/baselines" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get baselines comparisons ◑
#
# GET /projects/{id}/baselines_comparisons
# operationId: tuleap\Baseline\REST\ProjectComparisonsResourceRetrieveComparisons
export def "projects-baselines-comparisons tuleapBaselineRESTProjectComparisonsResourceRetrieveComparisons" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements to fetch (not authorized element are hidden, so you may get less element than requested) (format: int64, default: 50)
  --offset: int # Position of the first element to display (first position is 0). Comparisons are sorted by creation date (most recent first) (format: int64)
]: nothing -> record<comparisons: string, total_count: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/baselines_comparisons" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET Gitlab Integrations. ◑
#
# GET /projects/{id}/gitlab_repositories
# operationId: tuleap\Gitlab\REST\v1\GitlabProjectResourceRetrieveGitlabRepositories
export def "projects-gitlab-repositories tuleapGitlabRESTv1GitlabProjectResourceRetrieveGitlabRepositories" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/gitlab_repositories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Define a program plan 🔐
#
# PUT /projects/{id}/program_plan
# operationId: tuleap\ProgramManagement\REST\v1\ProjectResourceUpdatePlan
# --permissions shape: {can_prioritize_features: list}
# --iteration shape: {iteration_tracker_id: int, iteration_label?: string, iteration_sub_label?: string}
export def "projects-program-plan tuleapProgramManagementRESTv1ProjectResourceUpdatePlan" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  program_increment_tracker_id: int # format: int64
  plannable_tracker_ids: list
  permissions: any # shape: {can_prioritize_features: list}
  --program-increment-label: string # | null
  --program-increment-sub-label: string # | null
  --iteration: any # shape: {iteration_tracker_id: int, iteration_label?: string, iteration_sub_label?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/program_plan")
  let body = {program_increment_tracker_id: $program_increment_tracker_id, plannable_tracker_ids: $plannable_tracker_ids, permissions: $permissions, program_increment_label: $program_increment_label, program_increment_sub_label: $program_increment_sub_label, iteration: $iteration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Define team projects of a program 🔐
#
# PUT /projects/{id}/program_teams
# operationId: tuleap\ProgramManagement\REST\v1\ProjectResourceUpdateTeam
export def "projects-program-teams tuleapProgramManagementRESTv1ProjectResourceUpdateTeam" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  team_ids: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/program_teams")
  let body = {team_ids: $team_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get program backlog ◑
#
# GET /projects/{id}/program_backlog
# operationId: tuleap\ProgramManagement\REST\v1\ProjectResourceRetrieveBacklog
export def "projects-program-backlog tuleapProgramManagementRESTv1ProjectResourceRetrieveBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/program_backlog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manipulate the program backlog 🔐
#
# PATCH /projects/{id}/program_backlog
# operationId: tuleap\ProgramManagement\REST\v1\ProjectResourceModifyBacklog
# --order shape: {ids: list, direction: "after"|"before", compared_to: int}
export def "projects-program-backlog tuleapProgramManagementRESTv1ProjectResourceModifyBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  add: list
  remove: list
  --remove-from-program-increment-to-add-to-the-backlog: string@bool-completer
  --order: any # shape: {ids: list, direction: "after"|"before", compared_to: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/program_backlog")
  let body = {add: $add, remove: $remove, remove_from_program_increment_to_add_to_the_backlog: $remove_from_program_increment_to_add_to_the_backlog, order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get program increments ◑
#
# GET /projects/{id}/program_increments
# operationId: tuleap\ProgramManagement\REST\v1\ProjectResourceRetrieveProgramIncrements
export def "projects-program-increments tuleapProgramManagementRESTv1ProjectResourceRetrieveProgramIncrements" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/program_increments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a token 🔓
#
# POST /tokens
# operationId: createTuleap\Token\REST\v1\TokenResource
export def "tokens createTuleapTokenRESTv1TokenResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  username: string # The username of the user
  password: string # The password of the user
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens")
  let body = {username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Expire all tokens 🔐
#
# DELETE /tokens
# operationId: tuleap\Token\REST\v1\TokenResourceRemoveAll
export def "tokens tuleapTokenRESTv1TokenResourceRemoveAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Expire a token 🔐
#
# DELETE /tokens/{id}
# operationId: removeTuleap\Token\REST\v1\TokenResource
export def "tokens removeTuleapTokenRESTv1TokenResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tokens/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user_group ◑
#
# GET /user_groups/{id}
# operationId: tuleap\Project\REST\v1\UserGroupResourceRetrieveId
export def "user-groups tuleapProjectRESTv1UserGroupResourceRetrieveId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, uri: string, label: string, users_uri: string, short_name: string, key: string, project: string, additional_information: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_groups/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users of a user_group 🔐
#
# GET /user_groups/{id}/users
# operationId: tuleap\Project\REST\v1\UserGroupResourceRetrieveUsers
export def "user-groups-users tuleapProjectRESTv1UserGroupResourceRetrieveUsers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --qp-query: string # User name to look for
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_groups/($id)/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Define users of a user_group 🔐
#
# PUT /user_groups/{id}/users
# operationId: tuleap\Project\REST\v1\UserGroupResourceUpdateUsers
export def "user-groups-users tuleapProjectRESTv1UserGroupResourceUpdateUsers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  user_references: list
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_groups/($id)/users")
  let body = {user_references: $user_references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST user_groups 🔐
#
# POST /user_groups
# operationId: tuleap\Project\REST\v1\UserGroupResourceCreateUgroups
export def "user-groups tuleapProjectRESTv1UserGroupResourceCreateUgroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  project_id: int # format: int64
  short_name: string
  --description: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_groups")
  let body = {project_id: $project_id, short_name: $short_name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user ◑
#
# GET /users/{id}
# operationId: tuleap\User\REST\v1\UserResourceRetrieveId
export def "users tuleapUserRESTv1UserResourceRetrieveId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial update of user details 🔐
#
# PATCH /users/{id}
# operationId: tuleap\User\REST\v1\UserResourceModifyUserDetails
export def "users tuleapUserRESTv1UserResourceModifyUserDetails" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  values: list # User fields values
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get users ◑
#
# GET /users
# operationId: retrieveTuleap\User\REST\v1\UserResource
export def "users retrieveTuleapUserRESTv1UserResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # Search string (3 chars min in length)
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of user groups the given user is member of 🔐
#
# GET /users/{id}/membership
# operationId: tuleap\User\REST\v1\UserResourceRetrieveMembership
export def "users-membership tuleapUserRESTv1UserResourceRetrieveMembership" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --scope: string@scope-completer # null $scope Scope to project permissions or platform permissions
  --format: string@format-completer # null $format Special format to display the groups, only works with project scope
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/membership" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dashboards ◑
#
# GET /users/{id}/dashboards
# operationId: tuleap\User\REST\v1\UserResourceRetrieveDashboards
export def "users-dashboards tuleapUserRESTv1UserResourceRetrieveDashboards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of dashboards displayed per page (format: int64, default: 50)
  --offset: int # Position of the first dashboard to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/dashboards" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user preference ◑
#
# GET /users/{id}/preferences
# operationId: tuleap\User\REST\v1\UserResourceRetrievePreferences
export def "users-preferences tuleapUserRESTv1UserResourceRetrievePreferences" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --key: string # Preference key
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/preferences" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user preference ◑
#
# DELETE /users/{id}/preferences
# operationId: tuleap\User\REST\v1\UserResourceRemovePreferences
export def "users-preferences tuleapUserRESTv1UserResourceRemovePreferences" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --key: string # Preference key
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/preferences" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set a user preference ◑
#
# PATCH /users/{id}/preferences
# operationId: tuleap\User\REST\v1\UserResourceModifyPreferences
export def "users-preferences tuleapUserRESTv1UserResourceModifyPreferences" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  key: string
  value: string # | false
]: any -> record<key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/preferences")
  let body = {key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the history of a user ◑
#
# GET /users/{id}/history
# operationId: tuleap\User\REST\v1\UserResourceRetrieveHistory
export def "users-history tuleapUserRESTv1UserResourceRetrieveHistory" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<entries: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/history")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clear the history of a user ◑
#
# PUT /users/{id}/history
# operationId: tuleap\User\REST\v1\UserResourceUpdateHistory
export def "users-history tuleapUserRESTv1UserResourceUpdateHistory" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  history_entries: list # History entries representation
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/history")
  let body = {history_entries: $history_entries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the access keys of a user 🔐
#
# GET /users/{id}/access_keys
# operationId: tuleap\User\REST\v1\UserResourceRetrieveAccessKeys
export def "users-access-keys tuleapUserRESTv1UserResourceRetrieveAccessKeys" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/access_keys" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user's artifacts 🔐
#
# GET /users/{id}/artifacts
# operationId: tuleap\Tracker\REST\Artifact\UsersArtifactsResourceRetrieveArtifacts
export def "users-artifacts tuleapTrackerRESTArtifactUsersArtifactsResourceRetrieveArtifacts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # What artifacts to retrieve
  --offset: int # Offset in the collection (format: int64)
  --limit: int # Limit of the collection being returned (format: int64, default: 250)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/artifacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timetracking times 🔐
#
# GET /users/{id}/timetracking
# operationId: tuleap\Timetracking\REST\v1\User\TimetrackingUserResourceRetrieveUserTimes
export def "users-timetracking tuleapTimetrackingRESTv1UserTimetrackingUserResourceRetrieveUserTimes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/timetracking" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create dashboard 🔐
#
# POST /user_dashboards
# operationId: createTuleap\User\REST\v1\UserDashboardsResource
export def "user-dashboards createTuleapUserRESTv1UserDashboardsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # Name of the dashboard
]: any -> record<id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_dashboards")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve membership information for a set of users 🔐
#
# GET /users_memberships
# operationId: retrieveTuleap\User\REST\v1\UserMembershipResource
export def "users-memberships retrieveTuleapUserRESTv1UserMembershipResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string@query-completer # Criterion to filter the results
  --offset: int # Number of elements displayed per page (format: int64)
  --limit: int # Position of the first element to display (format: int64, default: 10)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users_memberships" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve fields for project creation 🔐
#
# GET /project_fields
# operationId: retrieveTuleap\REST\v1\ProjectFieldsResource
export def "project-fields retrieveTuleapRESTv1ProjectFieldsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<project_fields_representation: list<any>, total_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/project_fields" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a PhpWiki page representation ◑
#
# GET /phpwiki/{id}
# operationId: retrieveTuleap\PhpWiki\REST\v1\PhpWikiResource
export def "phpwiki retrieveTuleapPhpWikiRESTv1PhpWikiResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<last_version: int, versions: list<any>, id: int, uri: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/phpwiki/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a PhpWiki page version representation ◑
#
# GET /phpwiki/{id}/versions
# operationId: tuleap\PhpWiki\REST\v1\PhpWikiResourceRetrieveVersions
export def "phpwiki-versions tuleapPhpWikiRESTv1PhpWikiResourceRetrieveVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --version-id: int # Id of the version to filter the collection. If version_id=0, we return the last version. (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version_id" $version_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/phpwiki/($id)/versions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of items referencing the given wiki page ◑
#
# GET /phpwiki/{id}/items_referencing_wiki_page
# operationId: tuleap\PhpWiki\REST\v1\PhpWikiResourceRetrieveItemsReferencingWikiPage
export def "phpwiki-items-referencing-wiki-page tuleapPhpWikiRESTv1PhpWikiResourceRetrieveItemsReferencingWikiPage" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/phpwiki/($id)/items_referencing_wiki_page")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# To have a json web token 🔓
#
# GET /jwt
# operationId: retrieveTuleap\JWT\REST\v1\JWTResource
export def "jwt retrieveTuleapJWTRESTv1JWTResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jwt")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get system events 🔐
#
# GET /system_event
# operationId: retrieveTuleap\SystemEvent\REST\v1\SystemEventResource
export def "system-event retrieveTuleapSystemEventRESTv1SystemEventResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-1 # Number of elements displayed per page
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system_event" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new access key 🔐
#
# POST /access_keys
# operationId: createTuleap\User\AccessKey\REST\AccessKeyResource
export def "access-keys createTuleapUserAccessKeyRESTAccessKeyResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  description: string
  --expiration-date: string
  --scopes: list
]: any -> record<identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access_keys")
  let body = {description: $description, expiration_date: $expiration_date, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about an access key 🔐
#
# GET /access_keys/{id}
# operationId: retrieveTuleap\User\AccessKey\REST\AccessKeyResource
export def "access-keys retrieveTuleapUserAccessKeyRESTAccessKeyResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, creation_date: string, expiration_date: string, description: string, last_used_on: string, last_used_by: string, scopes: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access_keys/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke an access key 🔐
#
# DELETE /access_keys/{id}
# operationId: removeTuleap\User\AccessKey\REST\AccessKeyResource
export def "access-keys removeTuleapUserAccessKeyRESTAccessKeyResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access_keys/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update service ◑
#
# PUT /project_services/{id}
# operationId: tuleap\Project\REST\v1\ServiceResourceUpdateId
export def "project-services tuleapProjectRESTv1ServiceResourceUpdateId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --is-enabled: string@bool-completer # Enable or disable the service
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project_services/($id)")
  let body = {is_enabled: $is_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new invitation 🔐
#
# POST /invitations
# operationId: createTuleap\InviteBuddy\REST\v1\InvitationsResource
export def "invitations createTuleapInviteBuddyRESTv1InvitationsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  emails: list
  --custom-message: string
  --project-id: int # format: int64
]: any -> record<failures: list<string>, already_project_members: list<string>, known_users_added_to_project_members: list<string>, known_users_not_alive: list<string>, known_users_are_restricted: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invitations")
  let body = {emails: $emails, custom_message: $custom_message, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Put banner 🔐
#
# PUT /banner
# operationId: tuleap\Platform\Banner\REST\v1\BannerResourceUpdateBanner
export def "banner tuleapPlatformBannerRESTv1BannerResourceUpdateBanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  message: string
  importance: string@importance-completer
  --expiration-date: string # Expiration date in ISO 8601 date format
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/banner")
  let body = {message: $message, importance: $importance, expiration_date: $expiration_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the banner message 🔐
#
# DELETE /banner
# operationId: tuleap\Platform\Banner\REST\v1\BannerResourceRemoveBanner
export def "banner tuleapPlatformBannerRESTv1BannerResourceRemoveBanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/banner")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get banner ◑
#
# GET /banner
# operationId: tuleap\Platform\Banner\REST\v1\BannerResourceRetrieveBanner
export def "banner tuleapPlatformBannerRESTv1BannerResourceRetrieveBanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<message: string, importance: string, expiration_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/banner")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Tuleap build version 🔓
#
# GET /version
# operationId: retrieveTuleap\BuildVersion\REST\v1\VersionResource
export def "version retrieveTuleapBuildVersionRESTv1VersionResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<flavor_name: string, version_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get item ◑
#
# GET /docman_items/{id}
# operationId: tuleap\Docman\REST\v1\DocmanItemsResourceRetrieveId
export def "docman-items tuleapDocmanRESTv1DocmanItemsResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --with-size: string@bool-completer # <b>Only for folders</b>. When true, the size of the folder in Bytes is returned in the representation. <div class="tlp-alert-info"> Please note <ul> <li>The size of a folder is computed on the documents of type "file", that is to say files and embedded files.</li> <li>The number of files is the sum of the number of files, embedded files and folders.</li> </ul> </div>
]: nothing -> record<id: int, title: string, description: string, post_processed_description: string, owner: string, last_update_date: string, creation_date: string, user_can_write: bool, user_can_delete: bool, type: string, file_properties: string, embedded_file_properties: string, link_properties: string, wiki_properties: string, parent_id: int, is_expanded: bool, can_user_manage: bool, lock_info: string, metadata: list<any>, has_approval_table: bool, is_approval_table_enabled: bool, approval_table: string, permissions_for_groups: record<can_read: list<any>, can_write: list<any>, can_manage: list<any>>, folder_properties: string, other_type_properties: string, item_icon: string, move_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_size" $with_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_items/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the content of a folder ◑
#
# GET /docman_items/{id}/docman_items
# operationId: tuleap\Docman\REST\v1\DocmanItemsResourceRetrieveDocumentItems
export def "docman-items-docman-items tuleapDocmanRESTv1DocmanItemsResourceRetrieveDocumentItems" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_items/($id)/docman_items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the parents of an item ◑
#
# GET /docman_items/{id}/parents
# operationId: tuleap\Docman\REST\v1\DocmanItemsResourceRetrieveParents
export def "docman-items-parents tuleapDocmanRESTv1DocmanItemsResourceRetrieveParents" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_items/($id)/parents" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the logs of an item ◑
#
# GET /docman_items/{id}/logs
# operationId: tuleap\Docman\REST\v1\DocmanItemsResourceRetrieveLogs
export def "docman-items-logs tuleapDocmanRESTv1DocmanItemsResourceRetrieveLogs" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_items/($id)/logs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all item approval tables ◑
#
# GET /docman_items/{id}/approval_tables
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceRetrieveAllApprovalTables
export def "docman-items-approval-tables tuleapDocmanRESTv1DocmanItemsApprovalTableResourceRetrieveAllApprovalTables" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements to fetch (format: int64, default: 50)
  --offset: int # Position of the first element to fetch (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_items/($id)/approval_tables" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specific item approval table ◑
#
# GET /docman_items/{id}/approval_table/{version}
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceRetrieveApprovalTableVersion
export def "docman-items-approval-table tuleapDocmanRESTv1DocmanItemsApprovalTableResourceRetrieveApprovalTableVersion" [
  id: int
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, table_owner: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>, approval_state: string, approval_request_date: string, has_been_approved: bool, version_id: int, version_number: int, version_label: string, notification_type: string, state: string, is_closed: bool, description: string, post_processed_description: string, reviewers: list<string>, reminder_occurence: int, version_open_href: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table/($version)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an approval table for item if none exists ◑
#
# POST /docman_items/{id}/approval_table
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceCreateApprovalTable
export def "docman-items-approval-table tuleapDocmanRESTv1DocmanItemsApprovalTableResourceCreateApprovalTable" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  users: list # List for reviewer users ids
  user_groups: list # List of reviewer user groups ids
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table")
  let body = {users: $users, user_groups: $user_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the current approval table of the document ◑
#
# PUT /docman_items/{id}/approval_table
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceUpdateApprovalTable
export def "docman-items-approval-table tuleapDocmanRESTv1DocmanItemsApprovalTableResourceUpdateApprovalTable" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  owner: int # ID of the table owner (format: int64)
  status: string@status-completer-2 # Status of the table
  --comment: string # Description of the table
  notification_type: string@notification-type-completer # How the table notify its reviewers
  reviewers: list # List of current reviewers ids. They are ordered with their rank. It is the wanted value for the reviewer table (minus user groups added in a later parameter) with added and removed user from previous value
  reviewers_group_to_add: list # List of user group ids to add to the reviewers (their members are added after the reviewers from <code>reviewers</code>)
  reminder_occurence: int # max> Amount of days between each reminder to approvers (format: int64)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table")
  let body = {owner: $owner, status: $status, comment: $comment, notification_type: $notification_type, reviewers: $reviewers, reviewers_group_to_add: $reviewers_group_to_add, reminder_occurence: $reminder_occurence} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Perform asked action on approval table ◑
#
# PATCH /docman_items/{id}/approval_table
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceModifyApprovalTable
export def "docman-items-approval-table tuleapDocmanRESTv1DocmanItemsApprovalTableResourceModifyApprovalTable" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  action: string@action-completer # Which action to perform on document approval table
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the last approval table for item ◑
#
# DELETE /docman_items/{id}/approval_table
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceRemoveApprovalTable
export def "docman-items-approval-table tuleapDocmanRESTv1DocmanItemsApprovalTableResourceRemoveApprovalTable" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change user review on approval table ◑
#
# PUT /docman_items/{id}/approval_table/review
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceUpdateApprovalTableReview
export def "docman-items-approval-table-review tuleapDocmanRESTv1DocmanItemsApprovalTableResourceUpdateApprovalTableReview" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  review: string@review-completer # Review state of user
  --comment: string # Review comment
  --notification: string@bool-completer # Receive email whenever the item is updated
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table/review")
  let body = {review: $review, comment: $comment, notification: $notification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a reminder to all approvers according to table notification type ◑
#
# POST /docman_items/{id}/approval_table/reminder
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceCreateApprovalTableReminder
export def "docman-items-approval-table-reminder tuleapDocmanRESTv1DocmanItemsApprovalTableResourceCreateApprovalTableReminder" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table/reminder")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Force send a reminder to a specific approver ◑
#
# POST /docman_items/{id}/approval_table/reminder/{reviewer_id}
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceCreateApprovalTableReviewerReminder
export def "docman-items-approval-table-reminder tuleapDocmanRESTv1DocmanItemsApprovalTableResourceCreateApprovalTableReviewerReminder" [
  id: int
  reviewer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/($id)/approval_table/reminder/($reviewer_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

#  🔓
#
# GET /docman_items/buildfromitemidforapprovaltables/{id}
# operationId: tuleap\Docman\REST\v1\DocmanItemsApprovalTableResourceBuildFromItemIdForApprovalTables
export def "docman-items-buildfromitemidforapprovaltables tuleapDocmanRESTv1DocmanItemsApprovalTableResourceBuildFromItemIdForApprovalTables" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_items/buildfromitemidforapprovaltables/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move an existing file document ◑
#
# PATCH /docman_files/{id}
# operationId: modifyTuleap\Docman\REST\v1\DocmanFilesResource
# --move shape: {destination_folder_id: int}
export def "docman-files modifyTuleapDocmanRESTv1DocmanFilesResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {destination_folder_id: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_files/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing file document ◑
#
# DELETE /docman_files/{id}
# operationId: removeTuleap\Docman\REST\v1\DocmanFilesResource
export def "docman-files removeTuleapDocmanRESTv1DocmanFilesResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_files/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock a specific file document ◑
#
# POST /docman_files/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanFilesResourceCreateLock
export def "docman-files-lock tuleapDocmanRESTv1DocmanFilesResourceCreateLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_files/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock an already locked file document ◑
#
# DELETE /docman_files/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanFilesResourceRemoveLock
export def "docman-files-lock tuleapDocmanRESTv1DocmanFilesResourceRemoveLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_files/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a version of a file 🔐
#
# POST /docman_files/{id}/versions
# operationId: tuleap\Docman\REST\v1\DocmanFilesResourceCreateVersions
# --file_properties shape: {file_name: string, file_size: int}
export def "docman-files-versions tuleapDocmanRESTv1DocmanFilesResourceCreateVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --version-title: string # Title of version
  --change-log: string # Description of changes
  file_properties: any # shape: {file_name: string, file_size: int}
  --should-lock-file: string@bool-completer # Lock file while updating
  --approval-table-action: string@approval-table-action-completer # | null action for approval table when an item is updated
]: any -> record<upload_href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_files/($id)/versions")
  let body = {version_title: $version_title, change_log: $change_log, file_properties: $file_properties, should_lock_file: $should_lock_file, approval_table_action: $approval_table_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the versions of an item ◑
#
# GET /docman_files/{id}/versions
# operationId: tuleap\Docman\REST\v1\DocmanFilesResourceRetrieveVersions
export def "docman-files-versions tuleapDocmanRESTv1DocmanFilesResourceRetrieveVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_files/($id)/versions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the file document metadata ◑
#
# PUT /docman_files/{id}/metadata
# operationId: tuleap\Docman\REST\v1\DocmanFilesResourceUpdateMetadata
export def "docman-files-metadata tuleapDocmanRESTv1DocmanFilesResourceUpdateMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # Item status
  --obsolescence-date: string # | null Obsolescence date
  owner_id: int # The new owner id of the item (format: int64)
  --metadata: list # | null
  title: string # Item title
  --description: string # Item description
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_files/($id)/metadata")
  let body = {status: $status, obsolescence_date: $obsolescence_date, owner_id: $owner_id, metadata: $metadata, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update permissions of a file document ◑
#
# PUT /docman_files/{id}/permissions
# operationId: tuleap\Docman\REST\v1\DocmanFilesResourceUpdatePermissions
export def "docman-files-permissions tuleapDocmanRESTv1DocmanFilesResourceUpdatePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  can_read: list
  can_write: list
  can_manage: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_files/($id)/permissions")
  let body = {can_read: $can_read, can_write: $can_write, can_manage: $can_manage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move an existing folder ◑
#
# PATCH /docman_folders/{id}
# operationId: modifyTuleap\Docman\REST\v1\DocmanFoldersResource
# --move shape: {destination_folder_id: int}
export def "docman-folders modifyTuleapDocmanRESTv1DocmanFoldersResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {destination_folder_id: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing folder and its content ◑
#
# DELETE /docman_folders/{id}
# operationId: removeTuleap\Docman\REST\v1\DocmanFoldersResource
export def "docman-folders removeTuleapDocmanRESTv1DocmanFoldersResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new file document ◑
#
# POST /docman_folders/{id}/files
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceCreateFiles
# --file_properties shape: {file_name: string, file_size: int}
# --permissions_for_groups shape: {can_read: list, can_write: list, can_manage: list}
# --copy shape: {item_id: int}
export def "docman-folders-files tuleapDocmanRESTv1DocmanFoldersResourceCreateFiles" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # Item title Mandatory if copy is not set
  --description: string # Item description
  --file-properties: any # shape: {file_name: string, file_size: int}
  --status: string@status-completer-3 # | null Item status
  --obsolescence-date: string # | null Obsolescence date
  --metadata: list # | null
  --permissions-for-groups: any # shape: {can_read: list, can_write: list, can_manage: list}
  --copy: any # shape: {item_id: int}
]: any -> record<id: int, uri: string, file_properties: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/files")
  let body = {title: $title, description: $description, file_properties: $file_properties, status: $status, obsolescence_date: $obsolescence_date, metadata: $metadata, permissions_for_groups: $permissions_for_groups, copy: $copy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new folder ◑
#
# POST /docman_folders/{id}/folders
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceCreateFolders
# --permissions_for_groups shape: {can_read: list, can_write: list, can_manage: list}
# --copy shape: {item_id: int}
export def "docman-folders-folders tuleapDocmanRESTv1DocmanFoldersResourceCreateFolders" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # Item title Mandatory if copy is not set
  --description: string # Item description
  --status: string@status-completer-3 # | null Item status
  --metadata: list # | null
  --permissions-for-groups: any # shape: {can_read: list, can_write: list, can_manage: list}
  --copy: any # shape: {item_id: int}
]: any -> record<id: int, uri: string, file_properties: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/folders")
  let body = {title: $title, description: $description, status: $status, metadata: $metadata, permissions_for_groups: $permissions_for_groups, copy: $copy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new empty document ◑
#
# POST /docman_folders/{id}/empties
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceCreateEmpties
# --permissions_for_groups shape: {can_read: list, can_write: list, can_manage: list}
# --copy shape: {item_id: int}
export def "docman-folders-empties tuleapDocmanRESTv1DocmanFoldersResourceCreateEmpties" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # Item title Mandatory if copy is not set
  --description: string # Item description
  --status: string@status-completer-3 # | null Item status
  --obsolescence-date: string # | null Obsolescence date
  --metadata: list # | null
  --permissions-for-groups: any # shape: {can_read: list, can_write: list, can_manage: list}
  --copy: any # shape: {item_id: int}
]: any -> record<id: int, uri: string, file_properties: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/empties")
  let body = {title: $title, description: $description, status: $status, obsolescence_date: $obsolescence_date, metadata: $metadata, permissions_for_groups: $permissions_for_groups, copy: $copy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new wiki document ◑
#
# POST /docman_folders/{id}/wikis
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceCreateWikis
# --wiki_properties shape: {page_name: string}
# --permissions_for_groups shape: {can_read: list, can_write: list, can_manage: list}
# --copy shape: {item_id: int}
export def "docman-folders-wikis tuleapDocmanRESTv1DocmanFoldersResourceCreateWikis" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # Item title Mandatory if copy is not set
  --description: string # Item description
  --wiki-properties: any # shape: {page_name: string}
  --status: string@status-completer-3 # | null Item status
  --obsolescence-date: string # | null Obsolescence date
  --metadata: list # | null
  --permissions-for-groups: any # shape: {can_read: list, can_write: list, can_manage: list}
  --copy: any # shape: {item_id: int}
]: any -> record<id: int, uri: string, file_properties: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/wikis")
  let body = {title: $title, description: $description, wiki_properties: $wiki_properties, status: $status, obsolescence_date: $obsolescence_date, metadata: $metadata, permissions_for_groups: $permissions_for_groups, copy: $copy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new embedded document ◑
#
# POST /docman_folders/{id}/embedded_files
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceCreateEmbeds
# --embedded_properties shape: {content?: string}
# --permissions_for_groups shape: {can_read: list, can_write: list, can_manage: list}
# --copy shape: {item_id: int}
export def "docman-folders-embedded-files tuleapDocmanRESTv1DocmanFoldersResourceCreateEmbeds" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # Item title Mandatory if copy is not set
  --description: string # Item description
  --embedded-properties: any # shape: {content?: string}
  --status: string@status-completer-3 # | null Item status
  --obsolescence-date: string # | null Obsolescence date
  --metadata: list # | null
  --permissions-for-groups: any # shape: {can_read: list, can_write: list, can_manage: list}
  --copy: any # shape: {item_id: int}
]: any -> record<id: int, uri: string, file_properties: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/embedded_files")
  let body = {title: $title, description: $description, embedded_properties: $embedded_properties, status: $status, obsolescence_date: $obsolescence_date, metadata: $metadata, permissions_for_groups: $permissions_for_groups, copy: $copy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new link document ◑
#
# POST /docman_folders/{id}/links
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceCreateLinks
# --link_properties shape: {link_url: string}
# --permissions_for_groups shape: {can_read: list, can_write: list, can_manage: list}
# --copy shape: {item_id: int}
export def "docman-folders-links tuleapDocmanRESTv1DocmanFoldersResourceCreateLinks" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # Item title Mandatory if copy is not set
  --description: string # Item description
  --link-properties: any # shape: {link_url: string}
  --status: string@status-completer-3 # | null Item status
  --obsolescence-date: string # | null Obsolescence date
  --metadata: list # | null
  --permissions-for-groups: any # shape: {can_read: list, can_write: list, can_manage: list}
  --copy: any # shape: {item_id: int}
]: any -> record<id: int, uri: string, file_properties: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/links")
  let body = {title: $title, description: $description, link_properties: $link_properties, status: $status, obsolescence_date: $obsolescence_date, metadata: $metadata, permissions_for_groups: $permissions_for_groups, copy: $copy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create new other type document ◑
#
# POST /docman_folders/{id}/others
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceCreateOthers
# --permissions_for_groups shape: {can_read: list, can_write: list, can_manage: list}
# --copy shape: {item_id: int}
export def "docman-folders-others tuleapDocmanRESTv1DocmanFoldersResourceCreateOthers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string # Item title Mandatory if copy is not set
  --description: string # Item description
  --status: string@status-completer-3 # | null Item status
  --obsolescence-date: string # | null Obsolescence date
  --metadata: list # | null The metadata
  --permissions-for-groups: any # shape: {can_read: list, can_write: list, can_manage: list}
  --type: string # | null The type of the item
  --copy: any # shape: {item_id: int}
]: any -> record<id: int, uri: string, file_properties: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/others")
  let body = {title: $title, description: $description, status: $status, obsolescence_date: $obsolescence_date, metadata: $metadata, permissions_for_groups: $permissions_for_groups, type: $type, copy: $copy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the folder metadata and apply this changes to its children ◑
#
# PUT /docman_folders/{id}/metadata
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceUpdateMetadata
# --status shape: {value?: "none"|"draft"|"approved"|"rejected", recursion: "none"|"folders"|"all_items"}
export def "docman-folders-metadata tuleapDocmanRESTv1DocmanFoldersResourceUpdateMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  status: any # shape: {value?: "none"|"draft"|"approved"|"rejected", recursion: "none"|"folders"|"all_items"}
  --metadata: list # | null
  title: string # Item title
  --description: string # Item description
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/metadata")
  let body = {status: $status, metadata: $metadata, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update permissions of a folder ◑
#
# PUT /docman_folders/{id}/permissions
# operationId: tuleap\Docman\REST\v1\DocmanFoldersResourceUpdatePermissions
export def "docman-folders-permissions tuleapDocmanRESTv1DocmanFoldersResourceUpdatePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --apply-permissions-on-children: string@bool-completer
  can_read: list
  can_write: list
  can_manage: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_folders/($id)/permissions")
  let body = {apply_permissions_on_children: $apply_permissions_on_children, can_read: $can_read, can_write: $can_write, can_manage: $can_manage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move an existing embedded file document ◑
#
# PATCH /docman_embedded_files/{id}
# operationId: modifyTuleap\Docman\REST\v1\DocmanEmbeddedFilesResource
# --move shape: {destination_folder_id: int}
export def "docman-embedded-files modifyTuleapDocmanRESTv1DocmanEmbeddedFilesResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {destination_folder_id: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_files/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing embedded file document ◑
#
# DELETE /docman_embedded_files/{id}
# operationId: removeTuleap\Docman\REST\v1\DocmanEmbeddedFilesResource
export def "docman-embedded-files removeTuleapDocmanRESTv1DocmanEmbeddedFilesResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_files/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock a specific embedded file document ◑
#
# POST /docman_embedded_files/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanEmbeddedFilesResourceCreateLock
export def "docman-embedded-files-lock tuleapDocmanRESTv1DocmanEmbeddedFilesResourceCreateLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_files/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock an already locked embedded file document ◑
#
# DELETE /docman_embedded_files/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanEmbeddedFilesResourceRemoveLock
export def "docman-embedded-files-lock tuleapDocmanRESTv1DocmanEmbeddedFilesResourceRemoveLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_files/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get versions ◑
#
# GET /docman_embedded_files/{id}/versions
# operationId: tuleap\Docman\REST\v1\DocmanEmbeddedFilesResourceRetrieveVersions
export def "docman-embedded-files-versions tuleapDocmanRESTv1DocmanEmbeddedFilesResourceRetrieveVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_embedded_files/($id)/versions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a version of an embedded file document 🔐
#
# POST /docman_embedded_files/{id}/versions
# operationId: tuleap\Docman\REST\v1\DocmanEmbeddedFilesResourceCreateVersions
# --embedded_properties shape: {content?: string}
export def "docman-embedded-files-versions tuleapDocmanRESTv1DocmanEmbeddedFilesResourceCreateVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --version-title: string # Title of version
  --change-log: string # Description of changes
  embedded_properties: any # shape: {content?: string}
  --should-lock-file: string@bool-completer # Lock file while updating
  --approval-table-action: string@approval-table-action-completer # | null action for approval table when an item is updated
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_files/($id)/versions")
  let body = {version_title: $version_title, change_log: $change_log, embedded_properties: $embedded_properties, should_lock_file: $should_lock_file, approval_table_action: $approval_table_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the embedded file document metadata ◑
#
# PUT /docman_embedded_files/{id}/metadata
# operationId: tuleap\Docman\REST\v1\DocmanEmbeddedFilesResourceUpdateMetadata
export def "docman-embedded-files-metadata tuleapDocmanRESTv1DocmanEmbeddedFilesResourceUpdateMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # Item status
  --obsolescence-date: string # | null Obsolescence date
  owner_id: int # The new owner id of the item (format: int64)
  --metadata: list # | null
  title: string # Item title
  --description: string # Item description
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_files/($id)/metadata")
  let body = {status: $status, obsolescence_date: $obsolescence_date, owner_id: $owner_id, metadata: $metadata, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update permissions of an embedded file document ◑
#
# PUT /docman_embedded_files/{id}/permissions
# operationId: tuleap\Docman\REST\v1\DocmanEmbeddedFilesResourceUpdatePermissions
export def "docman-embedded-files-permissions tuleapDocmanRESTv1DocmanEmbeddedFilesResourceUpdatePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  can_read: list
  can_write: list
  can_manage: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_files/($id)/permissions")
  let body = {can_read: $can_read, can_write: $can_write, can_manage: $can_manage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move an existing wiki document ◑
#
# PATCH /docman_wikis/{id}
# operationId: modifyTuleap\Docman\REST\v1\DocmanWikiResource
# --move shape: {destination_folder_id: int}
export def "docman-wikis modifyTuleapDocmanRESTv1DocmanWikiResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {destination_folder_id: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_wikis/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing wiki document ◑
#
# DELETE /docman_wikis/{id}
# operationId: removeTuleap\Docman\REST\v1\DocmanWikiResource
export def "docman-wikis removeTuleapDocmanRESTv1DocmanWikiResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --delete-associated-wiki-page: string@bool-completer
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_associated_wiki_page" $delete_associated_wiki_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_wikis/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a version of a wiki document 🔐
#
# POST /docman_wikis/{id}/versions
# operationId: tuleap\Docman\REST\v1\DocmanWikiResourceCreateVersions
# --wiki_properties shape: {page_name: string}
export def "docman-wikis-versions tuleapDocmanRESTv1DocmanWikiResourceCreateVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --version-title: string # Title of version
  --change-log: string # Description of changes
  wiki_properties: any # shape: {page_name: string}
  --should-lock-file: string@bool-completer # Lock file while updating
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_wikis/($id)/versions")
  let body = {version_title: $version_title, change_log: $change_log, wiki_properties: $wiki_properties, should_lock_file: $should_lock_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the wiki document metadata ◑
#
# PUT /docman_wikis/{id}/metadata
# operationId: tuleap\Docman\REST\v1\DocmanWikiResourceUpdateMetadata
export def "docman-wikis-metadata tuleapDocmanRESTv1DocmanWikiResourceUpdateMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # Item status
  --obsolescence-date: string # | null Obsolescence date
  owner_id: int # The new owner id of the item (format: int64)
  --metadata: list # | null
  title: string # Item title
  --description: string # Item description
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_wikis/($id)/metadata")
  let body = {status: $status, obsolescence_date: $obsolescence_date, owner_id: $owner_id, metadata: $metadata, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lock a specific wiki document ◑
#
# POST /docman_wikis/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanWikiResourceCreateLock
export def "docman-wikis-lock tuleapDocmanRESTv1DocmanWikiResourceCreateLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_wikis/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock an already locked wiki document ◑
#
# DELETE /docman_wikis/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanWikiResourceRemoveLock
export def "docman-wikis-lock tuleapDocmanRESTv1DocmanWikiResourceRemoveLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_wikis/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update permissions of a wiki document ◑
#
# PUT /docman_wikis/{id}/permissions
# operationId: tuleap\Docman\REST\v1\DocmanWikiResourceUpdatePermissions
export def "docman-wikis-permissions tuleapDocmanRESTv1DocmanWikiResourceUpdatePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  can_read: list
  can_write: list
  can_manage: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_wikis/($id)/permissions")
  let body = {can_read: $can_read, can_write: $can_write, can_manage: $can_manage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move an existing link document ◑
#
# PATCH /docman_links/{id}
# operationId: modifyTuleap\Docman\REST\v1\DocmanLinksResource
# --move shape: {destination_folder_id: int}
export def "docman-links modifyTuleapDocmanRESTv1DocmanLinksResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {destination_folder_id: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_links/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing link document ◑
#
# DELETE /docman_links/{id}
# operationId: removeTuleap\Docman\REST\v1\DocmanLinksResource
export def "docman-links removeTuleapDocmanRESTv1DocmanLinksResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_links/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock a specific link document ◑
#
# POST /docman_links/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanLinksResourceCreateLock
export def "docman-links-lock tuleapDocmanRESTv1DocmanLinksResourceCreateLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_links/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock an already locked link document ◑
#
# DELETE /docman_links/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanLinksResourceRemoveLock
export def "docman-links-lock tuleapDocmanRESTv1DocmanLinksResourceRemoveLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_links/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a version of a link 🔐
#
# POST /docman_links/{id}/versions
# operationId: tuleap\Docman\REST\v1\DocmanLinksResourceCreateVersions
# --link_properties shape: {link_url: string}
export def "docman-links-versions tuleapDocmanRESTv1DocmanLinksResourceCreateVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --version-title: string # Title of version
  --change-log: string # Description of changes
  link_properties: any # shape: {link_url: string}
  --should-lock-file: string@bool-completer # Lock file while updating
  --approval-table-action: string@approval-table-action-completer # | null action for approval table when an item is updated
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_links/($id)/versions")
  let body = {version_title: $version_title, change_log: $change_log, link_properties: $link_properties, should_lock_file: $should_lock_file, approval_table_action: $approval_table_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the versions of a link ◑
#
# GET /docman_links/{id}/versions
# operationId: tuleap\Docman\REST\v1\DocmanLinksResourceRetrieveVersions
export def "docman-links-versions tuleapDocmanRESTv1DocmanLinksResourceRetrieveVersions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docman_links/($id)/versions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the link document metadata ◑
#
# PUT /docman_links/{id}/metadata
# operationId: tuleap\Docman\REST\v1\DocmanLinksResourceUpdateMetadata
export def "docman-links-metadata tuleapDocmanRESTv1DocmanLinksResourceUpdateMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # Item status
  --obsolescence-date: string # | null Obsolescence date
  owner_id: int # The new owner id of the item (format: int64)
  --metadata: list # | null
  title: string # Item title
  --description: string # Item description
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_links/($id)/metadata")
  let body = {status: $status, obsolescence_date: $obsolescence_date, owner_id: $owner_id, metadata: $metadata, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update permissions of a link document ◑
#
# PUT /docman_links/{id}/permissions
# operationId: tuleap\Docman\REST\v1\DocmanLinksResourceUpdatePermissions
export def "docman-links-permissions tuleapDocmanRESTv1DocmanLinksResourceUpdatePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  can_read: list
  can_write: list
  can_manage: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_links/($id)/permissions")
  let body = {can_read: $can_read, can_write: $can_write, can_manage: $can_manage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move an existing empty document ◑
#
# PATCH /docman_empty_documents/{id}
# operationId: modifyTuleap\Docman\REST\v1\DocmanEmptyDocumentsResource
# --move shape: {destination_folder_id: int}
export def "docman-empty-documents modifyTuleapDocmanRESTv1DocmanEmptyDocumentsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {destination_folder_id: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing empty document ◑
#
# DELETE /docman_empty_documents/{id}
# operationId: removeTuleap\Docman\REST\v1\DocmanEmptyDocumentsResource
export def "docman-empty-documents removeTuleapDocmanRESTv1DocmanEmptyDocumentsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock a specific empty document ◑
#
# POST /docman_empty_documents/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanEmptyDocumentsResourceCreateLock
export def "docman-empty-documents-lock tuleapDocmanRESTv1DocmanEmptyDocumentsResourceCreateLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock an already locked empty document ◑
#
# DELETE /docman_empty_documents/{id}/lock
# operationId: tuleap\Docman\REST\v1\DocmanEmptyDocumentsResourceRemoveLock
export def "docman-empty-documents-lock tuleapDocmanRESTv1DocmanEmptyDocumentsResourceRemoveLock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)/lock")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the empty document metadata ◑
#
# PUT /docman_empty_documents/{id}/metadata
# operationId: tuleap\Docman\REST\v1\DocmanEmptyDocumentsResourceUpdateMetadata
export def "docman-empty-documents-metadata tuleapDocmanRESTv1DocmanEmptyDocumentsResourceUpdateMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # Item status
  --obsolescence-date: string # | null Obsolescence date
  owner_id: int # The new owner id of the item (format: int64)
  --metadata: list # | null
  title: string # Item title
  --description: string # Item description
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)/metadata")
  let body = {status: $status, obsolescence_date: $obsolescence_date, owner_id: $owner_id, metadata: $metadata, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an embedded file document ◑
#
# POST /docman_empty_documents/{id}/embedded_file
# operationId: tuleap\Docman\REST\v1\DocmanEmptyDocumentsResourceCreateEmbeddedFileVersion
export def "docman-empty-documents-embedded-file tuleapDocmanRESTv1DocmanEmptyDocumentsResourceCreateEmbeddedFileVersion" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --content: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)/embedded_file")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a link document ◑
#
# POST /docman_empty_documents/{id}/link
# operationId: tuleap\Docman\REST\v1\DocmanEmptyDocumentsResourceCreateLinkVersion
export def "docman-empty-documents-link tuleapDocmanRESTv1DocmanEmptyDocumentsResourceCreateLinkVersion" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  link_url: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)/link")
  let body = {link_url: $link_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a file document ◑
#
# POST /docman_empty_documents/{id}/file
# operationId: tuleap\Docman\REST\v1\DocmanEmptyDocumentsResourceCreateFileVersion
export def "docman-empty-documents-file tuleapDocmanRESTv1DocmanEmptyDocumentsResourceCreateFileVersion" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  file_name: string # Name of the file
  file_size: int # Size of the file (format: int64)
]: any -> record<upload_href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)/file")
  let body = {file_name: $file_name, file_size: $file_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update permissions of an empty document ◑
#
# PUT /docman_empty_documents/{id}/permissions
# operationId: tuleap\Docman\REST\v1\DocmanEmptyDocumentsResourceUpdatePermissions
export def "docman-empty-documents-permissions tuleapDocmanRESTv1DocmanEmptyDocumentsResourceUpdatePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  can_read: list
  can_write: list
  can_manage: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_empty_documents/($id)/permissions")
  let body = {can_read: $can_read, can_write: $can_write, can_manage: $can_manage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing other type document ◑
#
# DELETE /docman_other_type_documents/{id}
# operationId: removeTuleap\Docman\REST\v1\DocmanOtherTypeDocumentsResource
export def "docman-other-type-documents removeTuleapDocmanRESTv1DocmanOtherTypeDocumentsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_other_type_documents/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the other type document metadata ◑
#
# PUT /docman_other_type_documents/{id}/metadata
# operationId: tuleap\Docman\REST\v1\DocmanOtherTypeDocumentsResourceUpdateMetadata
export def "docman-other-type-documents-metadata tuleapDocmanRESTv1DocmanOtherTypeDocumentsResourceUpdateMetadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # Item status
  --obsolescence-date: string # | null Obsolescence date
  owner_id: int # The new owner id of the item (format: int64)
  --metadata: list # | null
  title: string # Item title
  --description: string # Item description
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_other_type_documents/($id)/metadata")
  let body = {status: $status, obsolescence_date: $obsolescence_date, owner_id: $owner_id, metadata: $metadata, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update permissions of the document ◑
#
# PUT /docman_other_type_documents/{id}/permissions
# operationId: tuleap\Docman\REST\v1\DocmanOtherTypeDocumentsResourceUpdatePermissions
export def "docman-other-type-documents-permissions tuleapDocmanRESTv1DocmanOtherTypeDocumentsResourceUpdatePermissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  can_read: list
  can_write: list
  can_manage: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_other_type_documents/($id)/permissions")
  let body = {can_read: $can_read, can_write: $can_write, can_manage: $can_manage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search items ◑
#
# POST /docman_search/{id}
# operationId: tuleap\Docman\REST\v1\SearchResourceSearch
export def "docman-search tuleapDocmanRESTv1SearchResourceSearch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --global-search: string # search in all string properties
  --properties: list
  --body-sort: list
  --limit: int # limit (format: int64)
  --offset: int # offset (format: int64)
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_search/($id)")
  let body = {global_search: $global_search, properties: $properties, sort: $body_sort, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete version 🔐
#
# DELETE /docman_file_versions/{id}
# operationId: tuleap\Docman\REST\v1\Files\FileVersionsResourceRemoveId
export def "docman-file-versions tuleapDocmanRESTv1FilesFileVersionsResourceRemoveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_file_versions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete version 🔐
#
# DELETE /docman_embedded_file_versions/{id}
# operationId: tuleap\Docman\REST\v1\EmbeddedFiles\EmbeddedFileVersionsResourceRemoveId
export def "docman-embedded-file-versions tuleapDocmanRESTv1EmbeddedFilesEmbeddedFileVersionsResourceRemoveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_file_versions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get content ◑
#
# GET /docman_embedded_file_versions/{id}/content
# operationId: tuleap\Docman\REST\v1\EmbeddedFiles\EmbeddedFileVersionsResourceRetrieveContent
export def "docman-embedded-file-versions-content tuleapDocmanRESTv1EmbeddedFilesEmbeddedFileVersionsResourceRetrieveContent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<version_number: int, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docman_embedded_file_versions/($id)/content")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

#  ◑
#
# GET /git/{id}
# operationId: retrieve\Tuleap\Git\REST\v1\RepositoryResource
export def "git retrieveTuleapGitRESTv1RepositoryResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string, name: string, label: string, path: string, path_without_project: string, description: string, last_update_date: string, permissions: string, server: string, html_url: string, default_branch: string, additional_information: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Git repository 🔐
#
# PATCH /git/{id}
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceModifyId
# --migrate_to_gerrit shape: {server: int, permissions: "default"|" none"}
export def "git TuleapGitRESTv1RepositoryResourceModifyId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --migrate-to-gerrit: any # shape: {server: int, permissions: "default"|" none"}
  --disconnect-from-gerrit: string@disconnect-from-gerrit-completer
  --default-branch: string # New default branch to set, the branch needs to exist
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/($id)")
  let body = {migrate_to_gerrit: $migrate_to_gerrit, disconnect_from_gerrit: $disconnect_from_gerrit, default_branch: $default_branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Post ◑
#
# POST /git
# operationId: create\Tuleap\Git\REST\v1\RepositoryResource
export def "git createTuleapGitRESTv1RepositoryResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  project_id: int # project id (format: int64)
  name: string # Repository name
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/git")
  let body = {project_id: $project_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Post a commit status ◑
#
# POST /git/{id_or_path}/statuses/{commit_reference}
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceCreateCommitStatus
export def "git-statuses TuleapGitRESTv1RepositoryResourceCreateCommitStatus" [
  id_or_path: string
  commit_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  state: string@state-completer
  --body-token: string
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/($id_or_path)/statuses/($commit_reference)")
  let body = {state: $state, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the tree of a git repository. ◑
#
# GET /git/{id}/tree
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceRetrieveTree
export def "git-tree TuleapGitRESTv1RepositoryResourceRetrieveTree" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --ref: string # reference
  --path: string # path of the file
  --offset: int # Position of the first element to display (format: int64)
  --limit: int # Number of elements displayed (format: int64, default: 50)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/git/($id)/tree" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the content of a specific file from a git repository. ◑
#
# GET /git/{id}/files
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceRetrieveFileContent
export def "git-files TuleapGitRESTv1RepositoryResourceRetrieveFileContent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --path-to-file: string # path of the file
  --ref: string # reference (default: master)
]: nothing -> record<encoding: string, size: int, name: string, path: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path_to_file" $path_to_file "scalar") (serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/git/($id)/files" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the branches of a git repository ◑
#
# GET /git/{id}/branches
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceRetrieveBranches
export def "git-branches TuleapGitRESTv1RepositoryResourceRetrieveBranches" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Position of the first element to display (format: int64)
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --format: string@format-completer-1 # Representation format of the commit (default: full)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/git/($id)/branches" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Git branch 🔐
#
# POST /git/{id}/branches
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceCreateBranch
export def "git-branches TuleapGitRESTv1RepositoryResourceCreateBranch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  branch_name: string
  reference: string
]: any -> record<name: string, html_url: string, commit: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/($id)/branches")
  let body = {branch_name: $branch_name, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all the tags of a git repository ◑
#
# GET /git/{id}/tags
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceRetrieveTags
export def "git-tags TuleapGitRESTv1RepositoryResourceRetrieveTags" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Position of the first element to display (format: int64)
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --format: string@format-completer-1 # Representation format of the commit (default: full)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/git/($id)/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit ◑
#
# GET /git/{id}/commits/{commit_reference}
# operationId: \Tuleap\Git\REST\v1\RepositoryResourceRetrieveCommits
export def "git-commits TuleapGitRESTv1RepositoryResourceRetrieveCommits" [
  id: int
  commit_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<author_name: string, authored_date: string, committed_date: string, title: string, message: string, author_email: string, author: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>, html_url: string, commit_status: record<name: string, date: string>, verification: record<signature: string>, cross_references: list<any>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/git/($id)/commits/($commit_reference)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull requests 🔐
#
# GET /git/{id}/pull_requests
# operationId: tuleap\PullRequest\REST\v1\RepositoryResourceRetrievePullRequests
export def "git-pull-requests tuleapPullRequestRESTv1RepositoryResourceRetrievePullRequests" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
  --order: string@order-completer # Sort order by pull request creation date (default: desc)
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<collection: string, total_size: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/git/($id)/pull_requests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull requests authors in a given git repository 🔐
#
# GET /git/{id}/pull_requests_authors
# operationId: tuleap\PullRequest\REST\v1\RepositoryResourceRetrievePullRequestsAuthors
export def "git-pull-requests-authors tuleapPullRequestRESTv1RepositoryResourceRetrievePullRequestsAuthors" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/git/($id)/pull_requests_authors" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull requests reviewers in a given git repository 🔐
#
# GET /git/{id}/pull_requests_reviewers
# operationId: tuleap\PullRequest\REST\v1\RepositoryResourceRetrievePullRequestsReviewers
export def "git-pull-requests-reviewers tuleapPullRequestRESTv1RepositoryResourceRetrievePullRequestsReviewers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/git/($id)/pull_requests_reviewers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Gerrit servers 🔐
#
# GET /gerrit
# operationId: retrieve\Tuleap\Git\REST\v1\GerritResource
export def "gerrit retrieveTuleapGitRESTv1GerritResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --for-project: int # The project ID to search in (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "for_project" $for_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gerrit" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tracker ◑
#
# GET /trackers/{id}
# operationId: tuleap\Tracker\REST\v1\TrackersResourceRetrieveId
export def "trackers tuleapTrackerRESTv1TrackersResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trackers/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial update of a tracker. 🔐
#
# PATCH /trackers/{id}
# operationId: tuleap\Tracker\REST\v1\TrackersResourceModifyWorkflow
export def "trackers tuleapTrackerRESTv1TrackersResourceModifyWorkflow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackers/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all reports of a given tracker ◑
#
# GET /trackers/{id}/tracker_reports
# operationId: tuleap\Tracker\REST\v1\TrackersResourceRetrieveReports
export def "trackers-tracker-reports tuleapTrackerRESTv1TrackersResourceRetrieveReports" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> table<id: int, uri: string, label: string, is_public: bool, is_default: bool, resources: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackers/($id)/tracker_reports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all artifacts of a given tracker ◑
#
# GET /trackers/{id}/artifacts
# operationId: tuleap\Tracker\REST\v1\TrackersResourceRetrieveArtifacts
export def "trackers-artifacts tuleapTrackerRESTv1TrackersResourceRetrieveArtifacts" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --values: string@values-completer # Which fields to include in the response. Default is no field values
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
  --offset: int # Position of the first element to display (format: int64)
  --qp-query: string # JSON object of search criteria properties
  --expert-query: string # Query with AND, OR, WITH|WITHOUT PARENT, WITH|WITHOUT CHILDREN, BETWEEN(), NOW(), IN(), NOT IN(), MYSELF(), parenthesis and Text, Integer, Float, Date, List fields <b>Does not work with query parameter</b>
  --order: string@order-completer # By default the artifacts are returned by Artifact ID ASC. Set this parameter to either ASC or DESC <b>Does not work with query and expert_query parameters</b> (default: asc)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "values" $values "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "expert_query" $expert_query "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackers/($id)/artifacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all possible parent artifacts for a given tracker ◑
#
# GET /trackers/{id}/parent_artifacts
# operationId: tuleap\Tracker\REST\v1\TrackersResourceRetrieveParentArtifacts
export def "trackers-parent-artifacts tuleapTrackerRESTv1TrackersResourceRetrieveParentArtifacts" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackers/($id)/parent_artifacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all currently used artifact link types in a tracker ◑
#
# GET /trackers/{id}/used_artifact_links
# operationId: tuleap\Tracker\REST\v1\TrackersResourceRetrieveUserArtifactLinkTypes
export def "trackers-used-artifact-links tuleapTrackerRESTv1TrackersResourceRetrieveUserArtifactLinkTypes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/trackers/($id)/used_artifact_links" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get artifacts ◑
#
# GET /artifacts
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceRetrieveArtifacts
export def "artifacts tuleapTrackerRESTv1ArtifactsResourceRetrieveArtifacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/artifacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create artifact 🔐
#
# POST /artifacts
# operationId: createTuleap\Tracker\REST\v1\ArtifactsResource
# --tracker shape: {id: int, uri?: string, label?: string, color?: string, project?: string}
# --from_artifact shape: {id: int, uri?: string, tracker?: any}
export def "artifacts createTuleapTrackerRESTv1ArtifactsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  tracker: any # shape: {id: int, uri?: string, label?: string, color?: string, project?: string}
  --values: list # Artifact fields values
  --values-by-field: list # Artifact fields values indexed by field
  --from-artifact: any # shape: {id: int, uri?: string, tracker?: any}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/artifacts")
  let body = {tracker: $tracker, values: $values, values_by_field: $values_by_field, from_artifact: $from_artifact} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get artifact ◑
#
# GET /artifacts/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceRetrieveId
export def "artifacts tuleapTrackerRESTv1ArtifactsResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --values-format: string@values-format-completer # The format of the value
  --tracker-structure-format: string@tracker-structure-format-completer # The format of the structure (default: minimal)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "values_format" $values_format "scalar") (serialize-qp "tracker_structure_format" $tracker_structure_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifacts/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an artifact given its id ◑
#
# DELETE /artifacts/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceRemoveArtifact
export def "artifacts tuleapTrackerRESTv1ArtifactsResourceRemoveArtifact" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifacts/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Artifact partial update 🔐
#
# PATCH /artifacts/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceModifyArtifact
# --move shape: {tracker_id: int, dry_run?: bool, should_populate_feedback_on_success?: bool}
export def "artifacts tuleapTrackerRESTv1ArtifactsResourceModifyArtifact" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {tracker_id: int, dry_run?: bool, should_populate_feedback_on_success?: bool}
]: any -> record<dry_run: record<fields: record<fields_migrated: list, fields_not_migrated: list, fields_partially_migrated: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifacts/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update artifact 🔐
#
# PUT /artifacts/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceUpdateId
# --comment shape: {body?: string, format: string}
export def "artifacts tuleapTrackerRESTv1ArtifactsResourceUpdateId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  values: list # Artifact fields values
  --comment: any # shape: {body?: string, format: string}
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifacts/($id)")
  let body = {values: $values, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get possible types for an artifact ◑
#
# GET /artifacts/{id}/links
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceRetrieveArtifactLinkTypes
export def "artifacts-links tuleapTrackerRESTv1ArtifactsResourceRetrieveArtifactLinkTypes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifacts/($id)/links")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all artifacts linked by type ◑
#
# GET /artifacts/{id}/linked_artifacts
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceRetrieveLinkedArtifacts
export def "artifacts-linked-artifacts tuleapTrackerRESTv1ArtifactsResourceRetrieveLinkedArtifacts" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --direction: string@direction-completer # The artifact link direction
  --nature: string # The artifact link type to filter
  --output-format: string@output-format-completer # Format of the response: nested (default) or a simplified and incomplete flat format (default: nested)
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "nature" $nature "scalar") (serialize-qp "output_format" $output_format "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifacts/($id)/linked_artifacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get changesets ◑
#
# GET /artifacts/{id}/changesets
# operationId: tuleap\Tracker\REST\v1\ArtifactsResourceRetrieveArtifactChangesets
export def "artifacts-changesets tuleapTrackerRESTv1ArtifactsResourceRetrieveArtifactChangesets" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-2 # Whether you want to fetch all fields or just comments (default: all)
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --order: string@order-completer # By default the changesets are returned by Changeset Id ASC. Set this parameter to either ASC or DESC (default: asc)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifacts/($id)/changesets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a chunk of a file 🔐
#
# GET /artifact_files/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactFilesResourceRetrieveId
export def "artifact-files tuleapTrackerRESTv1ArtifactFilesResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Where to start to read the file (format: int64)
  --limit: int # How much to read the file (format: int64, default: 1048576)
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact_files/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get files representation 🔐
#
# GET /artifact_temporary_files
# operationId: retrieveTuleap\Tracker\REST\v1\ArtifactTemporaryFilesResource
export def "artifact-temporary-files retrieveTuleapTrackerRESTv1ArtifactTemporaryFilesResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/artifact_temporary_files" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a temporary file 🔐
#
# POST /artifact_temporary_files
# operationId: createTuleap\Tracker\REST\v1\ArtifactTemporaryFilesResource
export def "artifact-temporary-files createTuleapTrackerRESTv1ArtifactTemporaryFilesResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # Name of the file
  mimetype: string # Mime-Type of the file
  content: string # First chunk of the file (base64-encoded)
  --description: string # Description of the file
]: any -> record<id: int, submitted_by: int, description: string, name: string, size: int, type: string, html_url: string, html_preview_url: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/artifact_temporary_files")
  let body = {name: $name, mimetype: $mimetype, content: $content, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a chunk of a file 🔐
#
# GET /artifact_temporary_files/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactTemporaryFilesResourceRetrieveId
export def "artifact-temporary-files tuleapTrackerRESTv1ArtifactTemporaryFilesResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Where to start to read the file (format: int64)
  --limit: int # How much to read the file (format: int64, default: 1048576)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact_temporary_files/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Append a chunk to a temporary file (not attached to any artifact) 🔐
#
# PUT /artifact_temporary_files/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactTemporaryFilesResourceUpdateId
export def "artifact-temporary-files tuleapTrackerRESTv1ArtifactTemporaryFilesResourceUpdateId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  content: string # Chunk of the file (base64-encoded)
  offset: int # Used to check that the chunk uploaded is the next one (minimum value is 2) (format: int64)
]: any -> record<id: int, submitted_by: int, description: string, name: string, size: int, type: string, html_url: string, html_preview_url: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact_temporary_files/($id)")
  let body = {content: $content, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a temporary file 🔐
#
# DELETE /artifact_temporary_files/{id}
# operationId: tuleap\Tracker\REST\v1\ArtifactTemporaryFilesResourceRemoveId
export def "artifact-temporary-files tuleapTrackerRESTv1ArtifactTemporaryFilesResourceRemoveId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact_temporary_files/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report ◑
#
# GET /tracker_reports/{id}
# operationId: tuleap\Tracker\REST\v1\ReportsResourceRetrieveId
export def "tracker-reports tuleapTrackerRESTv1ReportsResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --with-unsaved-changes: string@bool-completer # Enable to take into account unsaved changes made to the report on your ongoing session
]: nothing -> record<id: int, uri: string, label: string, is_public: bool, is_default: bool, resources: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_unsaved_changes" $with_unsaved_changes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracker_reports/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get artifacts ◑
#
# GET /tracker_reports/{id}/artifacts
# operationId: tuleap\Tracker\REST\v1\ReportsResourceRetrieveArtifacts
export def "tracker-reports-artifacts tuleapTrackerRESTv1ReportsResourceRetrieveArtifacts" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --with-unsaved-changes: string@bool-completer # Enable to take into account unsaved changes made to the report on your ongoing session
  --values: string@values-completer-1 # Which fields to include in the response. Default is no field values
  --table-renderer-id: int # null $table_renderer_id Which table renderer to use when values=from_table_renderer (format: int64)
  --output-format: string@output-format-completer # Format of the response: nested (default) or a simplified and incomplete flat format (default: nested)
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_unsaved_changes" $with_unsaved_changes "scalar") (serialize-qp "values" $values "scalar") (serialize-qp "table_renderer_id" $table_renderer_id "scalar") (serialize-qp "output_format" $output_format "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracker_reports/($id)/artifacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial update of a tracker field 🔐
#
# PATCH /tracker_fields/{id}
# operationId: modifyTuleap\Tracker\REST\v1\TrackerFieldsResource
# --move shape: {parent_id?: int, next_sibling_id?: int}
export def "tracker-fields modifyTuleapTrackerRESTv1TrackerFieldsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --label: string # | null The new label of the form element
  --description: string # | null The new description of the form element
  --name: string # | null The new name of the form element
  --new-values: list # | null The new values for list field
  --use-it: string@bool-completer # | null Unuse or use the form element
  --move: any # shape: {parent_id?: int, next_sibling_id?: int}
]: any -> record<field_id: int, label: string, name: string, type: string, values: list<any>, required: bool, collapsed: bool, bindings: list<string>, permissions: list<any>, permissions_for_groups: string, default_value: string, has_notifications: bool, is_used: bool, description: string, specific_properties: list<string>, label_decorators: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_fields/($id)")
  let body = {label: $label, description: $description, name: $name, new_values: $new_values, use_it: $use_it, move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete permanently tracker field 🔐
#
# DELETE /tracker_fields/{id}
# operationId: removeTuleap\Tracker\REST\v1\TrackerFieldsResource
export def "tracker-fields removeTuleapTrackerRESTv1TrackerFieldsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_fields/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create file 🔐
#
# POST /tracker_fields/{id}/files
# operationId: tuleap\Tracker\REST\v1\TrackerFieldsResourceCreateFiles
export def "tracker-fields-files tuleapTrackerRESTv1TrackerFieldsResourceCreateFiles" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The file name
  file_size: int # The file size (format: int64)
  file_type: string # The file type
  --description: string # | null Description of the file
]: any -> record<id: int, download_href: string, upload_href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_fields/($id)/files")
  let body = {name: $name, file_size: $file_size, file_type: $file_type, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new transition for a tracker workflow 🔐
#
# POST /tracker_workflow_transitions
# operationId: tuleap\Tracker\REST\v1\Workflow\TransitionsResourceCreateTransition
export def "tracker-workflow-transitions tuleapTrackerRESTv1WorkflowTransitionsResourceCreateTransition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  tracker_id: int # Id of the tracker (format: int64)
  from_id: int # Transition source as a field value id (format: int64)
  to_id: int # Transition destination as a field value id (format: int64)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracker_workflow_transitions")
  let body = {tracker_id: $tracker_id, from_id: $from_id, to_id: $to_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a transition from a workflow 🔐
#
# DELETE /tracker_workflow_transitions/{id}
# operationId: tuleap\Tracker\REST\v1\Workflow\TransitionsResourceRemoveTransition
export def "tracker-workflow-transitions tuleapTrackerRESTv1WorkflowTransitionsResourceRemoveTransition" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_workflow_transitions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a transition from a workflow 🔐
#
# PATCH /tracker_workflow_transitions/{id}
# operationId: tuleap\Tracker\REST\v1\Workflow\TransitionsResourceModifyTransition
export def "tracker-workflow-transitions tuleapTrackerRESTv1WorkflowTransitionsResourceModifyTransition" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  authorized_user_group_ids: list # Authorized user group id
  not_empty_field_ids: list # Ids of not empty fields
  --is-comment-required: string@bool-completer
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_workflow_transitions/($id)")
  let body = {authorized_user_group_ids: $authorized_user_group_ids, not_empty_field_ids: $not_empty_field_ids, is_comment_required: $is_comment_required} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a transition 🔐
#
# GET /tracker_workflow_transitions/{id}
# operationId: tuleap\Tracker\REST\v1\Workflow\TransitionsResourceRetrieveTransition
export def "tracker-workflow-transitions tuleapTrackerRESTv1WorkflowTransitionsResourceRetrieveTransition" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, from_id: int, to_id: int, authorized_user_group_ids: list<any>, not_empty_field_ids: list<int>, is_comment_required: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_workflow_transitions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all post actions of a transition 🔐
#
# GET /tracker_workflow_transitions/{id}/actions
# operationId: tuleap\Tracker\REST\v1\Workflow\TransitionsResourceRetrievePostActions
export def "tracker-workflow-transitions-actions tuleapTrackerRESTv1WorkflowTransitionsResourceRetrievePostActions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_workflow_transitions/($id)/actions")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update all post actions of a transition. 🔐
#
# PUT /tracker_workflow_transitions/{id}/actions
# operationId: tuleap\Tracker\REST\v1\Workflow\TransitionsResourceUpdatePostActions
export def "tracker-workflow-transitions-actions tuleapTrackerRESTv1WorkflowTransitionsResourceUpdatePostActions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  post_actions: list # $post_actions
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tracker_workflow_transitions/($id)/actions")
  let body = {post_actions: $post_actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Put children in a given milestone 🔐
#
# PUT /milestones/{id}/milestones
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceUpdateSubmilestones
export def "milestones-milestones TuleapAgileDashboardRESTv1MilestoneResourceUpdateSubmilestones" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  ids: list # Ids of the new milestones
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/milestones")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch children of a given milestone 🔐
#
# PATCH /milestones/{id}/milestones
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceModifySubmilestones
export def "milestones-milestones TuleapAgileDashboardRESTv1MilestoneResourceModifySubmilestones" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --add: list # Submilestones to add in milestone
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/milestones")
  let body = {add: $add} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sub-milestones ◑
#
# GET /milestones/{id}/milestones
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceRetrieveMilestones
export def "milestones-milestones TuleapAgileDashboardRESTv1MilestoneResourceRetrieveMilestones" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-1 # Set of fields to return in the result (default: all)
  --qp-query: string # JSON object of search criteria properties
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --order: string@order-completer # In which order milestones are fetched. Default is asc (default: asc)
]: nothing -> table<id: int, description: string, post_processed_description: string, uri: string, label: string, submitted_by: int, submitted_on: string, planning: string, project: string, start_date: string, end_date: string, number_days_since_start: int, number_days_until_end: int, capacity: float, remaining_effort: float, status_value: string, semantic_status: string, parent: string, artifact: string, sub_milestones_uri: string, sub_milestone_type: string, backlog_uri: string, content_uri: string, cardwall_uri: string, burndown_uri: string, last_modified_date: string, status_count: list<string>, has_user_priority_change_permission: bool, resources: list<string>, original_project_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/milestones/($id)/milestones" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get milestone ◑
#
# GET /milestones/{id}
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceRetrieveId
export def "milestones TuleapAgileDashboardRESTv1MilestoneResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, description: string, post_processed_description: string, uri: string, label: string, submitted_by: int, submitted_on: string, planning: string, project: string, start_date: string, end_date: string, number_days_since_start: int, number_days_until_end: int, capacity: float, remaining_effort: float, status_value: string, semantic_status: string, parent: string, artifact: string, sub_milestones_uri: string, sub_milestone_type: string, backlog_uri: string, content_uri: string, cardwall_uri: string, burndown_uri: string, last_modified_date: string, status_count: list<string>, has_user_priority_change_permission: bool, resources: list<string>, original_project_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Siblings ◑
#
# GET /milestones/{id}/siblings
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceRetrieveSiblings
export def "milestones-siblings TuleapAgileDashboardRESTv1MilestoneResourceRetrieveSiblings" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> table<id: int, description: string, post_processed_description: string, uri: string, label: string, submitted_by: int, submitted_on: string, planning: string, project: string, start_date: string, end_date: string, number_days_since_start: int, number_days_until_end: int, capacity: float, remaining_effort: float, status_value: string, semantic_status: string, parent: string, artifact: string, sub_milestones_uri: string, sub_milestone_type: string, backlog_uri: string, content_uri: string, cardwall_uri: string, burndown_uri: string, last_modified_date: string, status_count: list<string>, has_user_priority_change_permission: bool, resources: list<string>, original_project_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/milestones/($id)/siblings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get content ◑
#
# GET /milestones/{id}/content
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceRetrieveContent
export def "milestones-content TuleapAgileDashboardRESTv1MilestoneResourceRetrieveContent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/milestones/($id)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Put content in a given milestone 🔐
#
# PUT /milestones/{id}/content
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceUpdateContent
export def "milestones-content TuleapAgileDashboardRESTv1MilestoneResourceUpdateContent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  ids: list # Ids of backlog items
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/content")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partial re-order of milestone content relative to one element 🔐
#
# PATCH /milestones/{id}/content
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceModifyContent
# --order shape: {ids: list, direction: string, compared_to: int}
export def "milestones-content TuleapAgileDashboardRESTv1MilestoneResourceModifyContent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --order: any # shape: {ids: list, direction: string, compared_to: int}
  --add: list # Ids to add/move to milestone content
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/content")
  let body = {order: $order, add: $add} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get backlog ◑
#
# GET /milestones/{id}/backlog
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceRetrieveBacklog
export def "milestones-backlog TuleapAgileDashboardRESTv1MilestoneResourceRetrieveBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
  --include: string # What to include in results (default: not_planned)
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/milestones/($id)/backlog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update backlog items priorities 🔐
#
# PUT /milestones/{id}/backlog
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceUpdateBacklog
export def "milestones-backlog TuleapAgileDashboardRESTv1MilestoneResourceUpdateBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  ids: list # Ids of backlog items
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/backlog")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partial re-order of milestone backlog relative to one element. 🔐
#
# PATCH /milestones/{id}/backlog
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceModifyBacklog
# --order shape: {ids: list, direction: string, compared_to: int}
export def "milestones-backlog TuleapAgileDashboardRESTv1MilestoneResourceModifyBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --order: any # shape: {ids: list, direction: string, compared_to: int}
  --add: list # Ids to add/move to milestone backlog
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/backlog")
  let body = {order: $order, add: $add} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add an item to the backlog of a milestone 🔐
#
# POST /milestones/{id}/backlog
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceCreateBacklog
export def "milestones-backlog TuleapAgileDashboardRESTv1MilestoneResourceCreateBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  artifact: list # Identification of the backlog item
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/backlog")
  let body = {artifact: $artifact} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Cardwall ◑
#
# GET /milestones/{id}/cardwall
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceRetrieveCardwall
export def "milestones-cardwall TuleapAgileDashboardRESTv1MilestoneResourceRetrieveCardwall" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/cardwall")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Burdown data ◑
#
# GET /milestones/{id}/burndown
# operationId: \Tuleap\AgileDashboard\REST\v1\MilestoneResourceRetrieveBurndown
export def "milestones-burndown TuleapAgileDashboardRESTv1MilestoneResourceRetrieveBurndown" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<start_date: string, duration: int, capacity: float, points: list<float>, is_under_calculation: bool, opening_days: list<int>, points_with_date: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/milestones/($id)/burndown")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get content ◑
#
# GET /milestones/{id}/testplan
# operationId: tuleap\TestPlan\REST\v1\MilestoneResourceRetrieveTestPlan
export def "milestones-testplan tuleapTestPlanRESTv1MilestoneResourceRetrieveTestPlan" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/milestones/($id)/testplan" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get milestones ◑
#
# GET /plannings/{id}/milestones
# operationId: \Tuleap\AgileDashboard\REST\v1\PlanningResourceRetrieveMilestones
export def "plannings-milestones TuleapAgileDashboardRESTv1PlanningResourceRetrieveMilestones" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> table<id: int, description: string, post_processed_description: string, uri: string, label: string, submitted_by: int, submitted_on: string, planning: string, project: string, start_date: string, end_date: string, number_days_since_start: int, number_days_until_end: int, capacity: float, remaining_effort: float, status_value: string, semantic_status: string, parent: string, artifact: string, sub_milestones_uri: string, sub_milestone_type: string, backlog_uri: string, content_uri: string, cardwall_uri: string, burndown_uri: string, last_modified_date: string, status_count: list<string>, has_user_priority_change_permission: bool, resources: list<string>, original_project_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plannings/($id)/milestones" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get backlog item ◑
#
# GET /backlog_items/{id}
# operationId: retrieve\Tuleap\AgileDashboard\REST\v1\BacklogItemResource
export def "backlog-items retrieveTuleapAgileDashboardRESTv1BacklogItemResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/backlog_items/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get children ◑
#
# GET /backlog_items/{id}/children
# operationId: \Tuleap\AgileDashboard\REST\v1\BacklogItemResourceRetrieveChildren
export def "backlog-items-children TuleapAgileDashboardRESTv1BacklogItemResourceRetrieveChildren" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/backlog_items/($id)/children" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial re-order of backlog items plus update of children 🔐
#
# PATCH /backlog_items/{id}/children
# operationId: modify\Tuleap\AgileDashboard\REST\v1\BacklogItemResource
# --order shape: {ids: list, direction: string, compared_to: int}
export def "backlog-items-children modifyTuleapAgileDashboardRESTv1BacklogItemResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --order: any # shape: {ids: list, direction: string, compared_to: int}
  --add: list # Ids to add to backlog_items content
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/backlog_items/($id)/children")
  let body = {order: $order, add: $add} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get test definitions ◑
#
# GET /backlog_items/{id}/test_definitions
# operationId: tuleap\TestPlan\REST\v1\BacklogItemResourceRetrieveTestDefinitions
export def "backlog-items-test-definitions tuleapTestPlanRESTv1BacklogItemResourceRetrieveTestDefinitions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --milestone-id: int # ID of the milestone (format: int64)
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "milestone_id" $milestone_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/backlog_items/($id)/test_definitions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update card content 🔐
#
# PUT /cards/{id}
# operationId: \Tuleap\Cardwall\REST\v1\CardsResourceUpdateId
export def "cards TuleapCardwallRESTv1CardsResourceUpdateId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  label: string # Label of the card
  values: list # Card's fields values
  --column-id: int # Where the card should stands (format: int64)
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)")
  let body = {label: $label, values: $values, column_id: $column_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create PullRequest 🔐
#
# POST /pull_requests
# operationId: create\Tuleap\PullRequest\REST\v1\PullRequestsResource
export def "pull-requests createTuleapPullRequestRESTv1PullRequestsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  repository_id: int # format: int64
  repository_dest_id: int # format: int64
  branch_src: string
  branch_dest: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pull_requests")
  let body = {repository_id: $repository_id, repository_dest_id: $repository_dest_id, branch_src: $branch_src, branch_dest: $branch_dest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pull request 🔐
#
# GET /pull_requests/{id}
# operationId: retrieve\Tuleap\PullRequest\REST\v1\PullRequestsResource
export def "pull-requests retrieveTuleapPullRequestRESTv1PullRequestsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<description: string, reference_src: string, reference_dest: string, head_reference: string, resources: list<any>, user_can_merge: bool, user_can_abandon: bool, user_can_update_labels: bool, user_can_update_reviewers: bool, merge_status: string, short_stat: record<files_changed: string, lines_added: string, lines_removed: string>, last_build_status: string, last_build_date: string, raw_title: string, raw_description: string, user_can_reopen: bool, status_info: record<status_type: string, status_date: string, status_updater: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>>, user_can_update_title_and_description: bool, description_format: string, post_processed_description: string, id: int, title: string, uri: string, repository: record<name: string, project: string, clone_http_url: string, clone_ssh_url: string, id: int, uri: string>, repository_dest: record<name: string, project: string, clone_http_url: string, clone_ssh_url: string, id: int, uri: string>, user_id: int, creator: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>, creation_date: string, branch_src: string, branch_dest: string, status: string, head: record<id: string>, is_git_reference_broken: bool, reviewers: table<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial update of a pull request 🔐
#
# PATCH /pull_requests/{id}
# operationId: modify\Tuleap\PullRequest\REST\v1\PullRequestsResource
export def "pull-requests modifyTuleapPullRequestRESTv1PullRequestsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --status: string
  --title: string
  --description: string
  --description-format: string
]: any -> record<description: string, reference_src: string, reference_dest: string, head_reference: string, resources: list<any>, user_can_merge: bool, user_can_abandon: bool, user_can_update_labels: bool, user_can_update_reviewers: bool, merge_status: string, short_stat: record<files_changed: string, lines_added: string, lines_removed: string>, last_build_status: string, last_build_date: string, raw_title: string, raw_description: string, user_can_reopen: bool, status_info: record<status_type: string, status_date: string, status_updater: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>>, user_can_update_title_and_description: bool, description_format: string, post_processed_description: string, id: int, title: string, uri: string, repository: record<name: string, project: string, clone_http_url: string, clone_ssh_url: string, id: int, uri: string>, repository_dest: record<name: string, project: string, clone_http_url: string, clone_ssh_url: string, id: int, uri: string>, user_id: int, creator: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>, creation_date: string, branch_src: string, branch_dest: string, status: string, head: record<id: string>, is_git_reference_broken: bool, reviewers: table<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)")
  let body = {status: $status, title: $title, description: $description, description_format: $description_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pull request commits ◑
#
# GET /pull_requests/{id}/commits
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceRetrieveCommits
export def "pull-requests-commits TuleapPullRequestRESTv1PullRequestsResourceRetrieveCommits" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of fetched comments (format: int64, default: 50)
  --offset: int # Position of the first comment to fetch (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pull_requests/($id)/commits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get labels 🔐
#
# GET /pull_requests/{id}/labels
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceRetrieveLabels
export def "pull-requests-labels TuleapPullRequestRESTv1PullRequestsResourceRetrieveLabels" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # format: int64, default: 50
  --offset: int # format: int64
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pull_requests/($id)/labels" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update labels 🔐
#
# PATCH /pull_requests/{id}/labels
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceModifyLabels
export def "pull-requests-labels TuleapPullRequestRESTv1PullRequestsResourceModifyLabels" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --add: list
  --remove: list
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)/labels")
  let body = {add: $add, remove: $remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pull request's impacted files 🔐
#
# GET /pull_requests/{id}/files
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceRetrieveFiles
export def "pull-requests-files TuleapPullRequestRESTv1PullRequestsResourceRetrieveFiles" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)/files")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the diff of a given file in a pull request 🔐
#
# GET /pull_requests/{id}/file_diff
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceRetrieveFileDiff
export def "pull-requests-file-diff TuleapPullRequestRESTv1PullRequestsResourceRetrieveFileDiff" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --path: string # File path
]: nothing -> record<lines: list<any>, inline_comments: list<any>, mime_type: string, charset: string, special_format: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pull_requests/($id)/file_diff" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post a new inline comment 🔐
#
# POST /pull_requests/{id}/inline-comments
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceCreateInline
export def "pull-requests-inline-comments TuleapPullRequestRESTv1PullRequestsResourceCreateInline" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  content: string
  --format: string@format-completer-2 # | null
  file_path: string
  unidiff_offset: int # format: int64
  position: string
  --parent-id: int # | null $parent_id (format: int64)
]: any -> record<id: int, file_path: string, unidiff_offset: int, position: string, post_date: string, last_edition_date: string, content: string, raw_content: string, post_processed_content: string, is_outdated: bool, type: string, parent_id: int, format: string, color: string, user: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)/inline-comments")
  let body = {content: $content, format: $format, file_path: $file_path, unidiff_offset: $unidiff_offset, position: $position, parent_id: $parent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pull request's timeline 🔐
#
# GET /pull_requests/{id}/timeline
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceRetrieveTimeline
export def "pull-requests-timeline TuleapPullRequestRESTv1PullRequestsResourceRetrieveTimeline" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of fetched comments (format: int64, default: 10)
  --offset: int # Position of the first comment to fetch (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pull_requests/($id)/timeline" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pull request's comments 🔐
#
# GET /pull_requests/{id}/comments
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceRetrieveComments
export def "pull-requests-comments TuleapPullRequestRESTv1PullRequestsResourceRetrieveComments" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of fetched comments (format: int64, default: 10)
  --offset: int # Position of the first comment to fetch (format: int64)
  --order: string@order-completer # In which order comments are fetched. Default is asc. (default: asc)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pull_requests/($id)/comments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post a new comment 🔐
#
# POST /pull_requests/{id}/comments
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceCreateComments
export def "pull-requests-comments TuleapPullRequestRESTv1PullRequestsResourceCreateComments" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  content: string
  --parent-id: int # | null $parent_id (format: int64)
  --format: string@format-completer-2 # | null $format
]: any -> record<id: int, post_date: string, last_edition_date: string, content: string, raw_content: string, post_processed_content: string, type: string, parent_id: int, format: string, color: string, user: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)/comments")
  let body = {content: $content, parent_id: $parent_id, format: $format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pull request's reviewers ◑
#
# GET /pull_requests/{id}/reviewers
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceRetrieveReviewers
export def "pull-requests-reviewers TuleapPullRequestRESTv1PullRequestsResourceRetrieveReviewers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<users: table<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)/reviewers")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set pull request's reviewers 🔐
#
# PUT /pull_requests/{id}/reviewers
# operationId: \Tuleap\PullRequest\REST\v1\PullRequestsResourceUpdateReviewers
export def "pull-requests-reviewers TuleapPullRequestRESTv1PullRequestsResourceUpdateReviewers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  users: list
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_requests/($id)/reviewers")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing comment 🔐
#
# PATCH /pull_request_comments/{id}
# operationId: tuleap\PullRequest\REST\v1\PullRequestCommentsResourceModifyCommentId
export def "pull-request-comments tuleapPullRequestRESTv1PullRequestCommentsResourceModifyCommentId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  content: string # The new content of the comment
]: any -> record<id: int, post_date: string, last_edition_date: string, content: string, raw_content: string, post_processed_content: string, type: string, parent_id: int, format: string, color: string, user: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_request_comments/($id)")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing comment 🔐
#
# PATCH /pull_request_inline_comments/{id}
# operationId: tuleap\PullRequest\REST\v1\PullRequestInlineCommentsResourceModifyCommentId
export def "pull-request-inline-comments tuleapPullRequestRESTv1PullRequestInlineCommentsResourceModifyCommentId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  content: string # The new content of the comment
]: any -> record<id: int, file_path: string, unidiff_offset: int, position: string, post_date: string, last_edition_date: string, content: string, raw_content: string, post_processed_content: string, is_outdated: bool, type: string, parent_id: int, format: string, color: string, user: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_request_inline_comments/($id)")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reply to a given inline comment 🔐
#
# POST /pull_request_inline_comments/{id}/reply
# operationId: tuleap\PullRequest\REST\v1\PullRequestInlineCommentsResourceCreateReply
export def "pull-request-inline-comments-reply tuleapPullRequestRESTv1PullRequestInlineCommentsResourceCreateReply" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  content: string # The content of the reply
  format: string@format-completer-2 # The format of the reply
]: any -> record<id: int, file_path: string, unidiff_offset: int, position: string, post_date: string, last_edition_date: string, content: string, raw_content: string, post_processed_content: string, is_outdated: bool, type: string, parent_id: int, format: string, color: string, user: record<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pull_request_inline_comments/($id)/reply")
  let body = {content: $content, format: $format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get release ◑
#
# GET /frs_release/{id}
# operationId: tuleap\FRS\REST\v1\ReleaseResourceRetrieveId
export def "frs-release tuleapFRSRESTv1ReleaseResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<STATUS: list<string>, id: int, uri: string, name: string, files: list<list<any>>, links: list<list<any>>, changelog: string, release_note: string, resources: list<list<any>>, project: string, artifact: string, license_approval: bool, package: string, status: string, permissions_for_groups: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/frs_release/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update release 🔐
#
# PATCH /frs_release/{id}
# operationId: tuleap\FRS\REST\v1\ReleaseResourceModifyId
export def "frs-release tuleapFRSRESTv1ReleaseResourceModifyId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string
  --release-note: string
  --changelog: string
  --status: string@status-completer-4
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/frs_release/($id)")
  let body = {name: $name, release_note: $release_note, changelog: $changelog, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get files ◑
#
# GET /frs_release/{id}/files
# operationId: tuleap\FRS\REST\v1\ReleaseResourceRetrieveFiles
export def "frs-release-files tuleapFRSRESTv1ReleaseResourceRetrieveFiles" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of files displayed per page (format: int64, default: 10)
  --offset: int # Position of the first file to display (format: int64)
]: nothing -> record<files: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/frs_release/($id)/files" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create release 🔐
#
# POST /frs_release
# operationId: createTuleap\FRS\REST\v1\ReleaseResource
export def "frs-release createTuleapFRSRESTv1ReleaseResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  package_id: int # format: int64
  name: string
  --release-note: string
  --changelog: string
  --status: string@status-completer-4
]: any -> record<STATUS: list<string>, id: int, uri: string, name: string, files: list<list<any>>, links: list<list<any>>, changelog: string, release_note: string, resources: list<list<any>>, project: string, artifact: string, license_approval: bool, package: string, status: string, permissions_for_groups: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/frs_release")
  let body = {package_id: $package_id, name: $name, release_note: $release_note, changelog: $changelog, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a package 🔐
#
# POST /frs_packages
# operationId: createTuleap\FRS\REST\v1\PackageResource
export def "frs-packages createTuleapFRSRESTv1PackageResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  project_id: int # The id of the project where we should create the package (format: int64)
  label: string # Label of the package
]: any -> record<project: string, resources: list<string>, permissions_for_groups: string, id: int, uri: string, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/frs_packages")
  let body = {project_id: $project_id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get FRS package ◑
#
# GET /frs_packages/{id}
# operationId: tuleap\FRS\REST\v1\PackageResourceRetrieveId
export def "frs-packages tuleapFRSRESTv1PackageResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<project: string, resources: list<string>, permissions_for_groups: string, id: int, uri: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/frs_packages/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get FRS releases ◑
#
# GET /frs_packages/{id}/frs_release
# operationId: tuleap\FRS\REST\v1\PackageResourceRetrieveReleases
export def "frs-packages-frs-release tuleapFRSRESTv1PackageResourceRetrieveReleases" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<collection: list<any>, total_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/frs_packages/($id)/frs_release" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file ◑
#
# GET /frs_files/{id}
# operationId: tuleap\FRS\REST\v1\FileResourceRetrieveId
export def "frs-files tuleapFRSRESTv1FileResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string, name: string, download_url: string, file_size: int, nb_download: int, arch: string, type: string, date: string, reference_md5: string, computed_md5: string, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/frs_files/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete file 🔐
#
# DELETE /frs_files/{id}
# operationId: tuleap\FRS\REST\v1\FileResourceRemoveId
export def "frs-files tuleapFRSRESTv1FileResourceRemoveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/frs_files/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create file 🔐
#
# POST /frs_files
# operationId: createTuleap\FRS\REST\v1\FileResource
export def "frs-files createTuleapFRSRESTv1FileResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  release_id: int # The id of the release (format: int64)
  name: string # The file name
  file_size: int # The file size (format: int64)
]: any -> record<upload_href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/frs_files")
  let body = {release_id: $release_id, name: $name, file_size: $file_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a CrossTracker widget ◑
#
# GET /crosstracker_widget/{id}
# operationId: tuleap\CrossTracker\REST\v1\CrossTrackerWidgetResourceRetrieveId
export def "crosstracker-widget tuleapCrossTrackerRESTv1CrossTrackerWidgetResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<queries: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crosstracker_widget/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get forward links ◑
#
# GET /crosstracker_widget/{id}/forward_links
# operationId: tuleap\CrossTracker\REST\v1\CrossTrackerWidgetResourceRetrieveForwardLinks
export def "crosstracker-widget-forward-links tuleapCrossTrackerRESTv1CrossTrackerWidgetResourceRetrieveForwardLinks" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --tql-query: string # TQL query
  --source-artifact-id: int # ID of the artifact (format: int64)
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<artifacts: list<string>, selected: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tql_query" $tql_query "scalar") (serialize-qp "source_artifact_id" $source_artifact_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/crosstracker_widget/($id)/forward_links" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get reverse links ◑
#
# GET /crosstracker_widget/{id}/reverse_links
# operationId: tuleap\CrossTracker\REST\v1\CrossTrackerWidgetResourceRetrieveReverseLinks
export def "crosstracker-widget-reverse-links tuleapCrossTrackerRESTv1CrossTrackerWidgetResourceRetrieveReverseLinks" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --tql-query: string # TQL query
  --target-artifact-id: int # ID of the artifact (format: int64)
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<artifacts: list<string>, selected: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tql_query" $tql_query "scalar") (serialize-qp "target_artifact_id" $target_artifact_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/crosstracker_widget/($id)/reverse_links" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get results of the CrossTracker query ◑
#
# GET /crosstracker_query/content
# operationId: tuleap\CrossTracker\REST\v1\CrossTrackerQueryResourceRetrieveContent
export def "crosstracker-query-content tuleapCrossTrackerRESTv1CrossTrackerQueryResourceRetrieveContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # The query to execute on the widget
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<artifacts: list<string>, selected: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crosstracker_query/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get results of the CrossTracker query ◑
#
# GET /crosstracker_query/{id}/content
# operationId: tuleap\CrossTracker\REST\v1\CrossTrackerQueryResourceRetrieveIdContent
export def "crosstracker-query-content tuleapCrossTrackerRESTv1CrossTrackerQueryResourceRetrieveIdContent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<artifacts: list<string>, selected: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/crosstracker_query/($id)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a CrossTracker query 🔐
#
# PUT /crosstracker_query/{id}
# operationId: updateTuleap\CrossTracker\REST\v1\CrossTrackerQueryResource
export def "crosstracker-query updateTuleapCrossTrackerRESTv1CrossTrackerQueryResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  tql_query: string # The TQL query
  title: string # The query title
  --description: string # The query description
  widget_id: int # The id of the widget the query belongs to (format: int64)
  --is-default: string@bool-completer # The query is displayed by default or not
]: any -> record<id: string, tql_query: string, title: string, description: string, is_default: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crosstracker_query/($id)")
  let body = {tql_query: $tql_query, title: $title, description: $description, widget_id: $widget_id, is_default: $is_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a query from its widget 🔐
#
# DELETE /crosstracker_query/{id}
# operationId: removeTuleap\CrossTracker\REST\v1\CrossTrackerQueryResource
export def "crosstracker-query removeTuleapCrossTrackerRESTv1CrossTrackerQueryResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crosstracker_query/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new query in the widget 🔐
#
# POST /crosstracker_query
# operationId: createTuleap\CrossTracker\REST\v1\CrossTrackerQueryResource
export def "crosstracker-query createTuleapCrossTrackerRESTv1CrossTrackerQueryResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  widget_id: int # ID of the widget (format: int64)
  tql_query: string # The TQL query
  title: string # The query title
  --description: string # The query description
  --is-default: string@bool-completer # The query is displayed by default or not
]: any -> record<id: string, tql_query: string, title: string, description: string, is_default: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crosstracker_query")
  let body = {widget_id: $widget_id, tql_query: $tql_query, title: $title, description: $description, is_default: $is_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new set of credential 🔓
#
# POST /dynamic_credentials
# operationId: createTuleap\DynamicCredentials\REST\DynamicCredentialsResource
export def "dynamic-credentials createTuleapDynamicCredentialsRESTDynamicCredentialsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  username: string # Username must be formatted as forge__dynamic_credential-&lt;identifier&gt; where &lt;identifier&gt; is a chosen value
  password: string
  expiration: string # Expiration date ISO8601 formatted
  signature: string # Base64 encoded signature associated with the request
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dynamic_credentials")
  let body = {username: $username, password: $password, expiration: $expiration, signature: $signature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a set of credential 🔓
#
# DELETE /dynamic_credentials/{username}
# operationId: tuleap\DynamicCredentials\REST\DynamicCredentialsResourceRemoveUsername
export def "dynamic-credentials tuleapDynamicCredentialsRESTDynamicCredentialsResourceRemoveUsername" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --signature: string # Base64 encoded signature associated with the request
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dynamic_credentials/($username)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SVN ◑
#
# GET /svn/{id}
# operationId: retrieve\Tuleap\SVN\REST\v1\RepositoryResource
export def "svn retrieveTuleapSVNRESTv1RepositoryResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<settings: record<commit_rules: record<is_reference_mandatory: string, is_commit_message_change_allowed: string>, immutable_tags: record<paths: list, whitelist: list>, access_file: string, email_notifications: list<any>, has_default_permissions: bool>, id: int, project: record<id: int, uri: string, label: string, label_without_icon: string, shortname: string, status: string, access: string, is_template: bool>, uri: string, name: string, svn_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/svn/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT SVN 🔐
#
# PUT /svn/{id}
# operationId: update\Tuleap\SVN\REST\v1\RepositoryResource
# --commit_rules shape: {is_reference_mandatory: string, is_commit_message_change_allowed: string}
# --immutable_tags shape: {paths: list, whitelist: list}
export def "svn updateTuleapSVNRESTv1RepositoryResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  commit_rules: any # shape: {is_reference_mandatory: string, is_commit_message_change_allowed: string}
  immutable_tags: any # shape: {paths: list, whitelist: list}
  email_notifications: list # notifications representations
  --access-file: string # access file content
  --has-default-permissions: string@bool-completer # If true, Tuleap generates default permissions for [/]
]: any -> record<settings: record<commit_rules: record<is_reference_mandatory: string, is_commit_message_change_allowed: string>, immutable_tags: record<paths: list, whitelist: list>, access_file: string, email_notifications: list<any>, has_default_permissions: bool>, id: int, project: record<id: int, uri: string, label: string, label_without_icon: string, shortname: string, status: string, access: string, is_template: bool>, uri: string, name: string, svn_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/svn/($id)")
  let body = {commit_rules: $commit_rules, immutable_tags: $immutable_tags, email_notifications: $email_notifications, access_file: $access_file, has_default_permissions: $has_default_permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete SVN repository 🔐
#
# DELETE /svn/{id}
# operationId: remove\Tuleap\SVN\REST\v1\RepositoryResource
export def "svn removeTuleapSVNRESTv1RepositoryResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/svn/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a SVN repository 🔐
#
# POST /svn
# operationId: create\Tuleap\SVN\REST\v1\RepositoryResource
# --settings shape: {layout?: list, commit_rules?: any, immutable_tags?: any, access_file?: string, email_notifications?: list, has_default_permissions?: bool}
export def "svn createTuleapSVNRESTv1RepositoryResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  project_id: int # project id (format: int64)
  name: string # Repository name
  --settings: any # shape: {layout?: list, commit_rules?: any, immutable_tags?: any, access_file?: string, email_notifications?: list, has_default_permissions?: bool}
]: any -> record<id: int, project: record<id: int, uri: string, label: string, label_without_icon: string, shortname: string, status: string, access: string, is_template: bool>, uri: string, name: string, svn_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/svn")
  let body = {project_id: $project_id, name: $name, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get campaign ◑
#
# GET /testmanagement_campaigns/{id}
# operationId: tuleap\TestManagement\REST\v1\CampaignsResourceRetrieveId
export def "testmanagement-campaigns tuleapTestManagementRESTv1CampaignsResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<total: int, id: string, label: string, status: string, uri: string, nb_of_notrun: string, nb_of_passed: string, nb_of_failed: string, nb_of_blocked: string, resources: string, job_configuration: string, user_can_update: string, is_open: bool, user_can_close: bool, user_can_open: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_campaigns/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH campaign 🔐
#
# PATCH /testmanagement_campaigns/{id}
# operationId: modifyTuleap\TestManagement\REST\v1\CampaignsResource
# --job_configuration shape: {url?: string, token?: string}
# --automated_tests_results shape: {build_url: string, junit_contents: list}
export def "testmanagement-campaigns modifyTuleapTestManagementRESTv1CampaignsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --label: string # New label of the campaign
  --job-configuration: any # shape: {url?: string, token?: string}
  --automated-tests-results: any # shape: {build_url: string, junit_contents: list}
  --change-status: string@change-status-completer # null $change_status
]: any -> record<total: int, id: string, label: string, status: string, uri: string, nb_of_notrun: string, nb_of_passed: string, nb_of_failed: string, nb_of_blocked: string, resources: string, job_configuration: string, user_can_update: string, is_open: bool, user_can_close: bool, user_can_open: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_campaigns/($id)")
  let body = {label: $label, job_configuration: $job_configuration, automated_tests_results: $automated_tests_results, change_status: $change_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get executions ◑
#
# GET /testmanagement_campaigns/{id}/testmanagement_executions
# operationId: tuleap\TestManagement\REST\v1\CampaignsResourceRetrieveExecutions
export def "testmanagement-campaigns-testmanagement-executions tuleapTestManagementRESTv1CampaignsResourceRetrieveExecutions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
  --definition-format: string@definition-format-completer # The format of the artifact defintion retrieved (default: minimal)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "definition_format" $definition_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/testmanagement_campaigns/($id)/testmanagement_executions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH test executions 🔐
#
# PATCH /testmanagement_campaigns/{id}/testmanagement_executions
# operationId: tuleap\TestManagement\REST\v1\CampaignsResourceModifyExecutions
export def "testmanagement-campaigns-testmanagement-executions tuleapTestManagementRESTv1CampaignsResourceModifyExecutions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  definition_ids_to_add: list # Test definition ids for which test executions should be created
  execution_ids_to_remove: list # Test execution ids which should be unlinked from the campaign
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_campaigns/($id)/testmanagement_executions")
  let body = {definition_ids_to_add: $definition_ids_to_add, execution_ids_to_remove: $execution_ids_to_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST campaign 🔐
#
# POST /testmanagement_campaigns
# operationId: createTuleap\TestManagement\REST\v1\CampaignsResource
export def "testmanagement-campaigns createTuleapTestManagementRESTv1CampaignsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --test-selector: string@test-selector-completer # The method used to set initial test definitions for campaign (default: all)
  --milestone-id: int # Id of the milestone with which the campaign will be linked (format: int64)
  --report-id: int # Id of the report to retrieve test definitions for campaign (format: int64)
  project_id: int # Id of the project the campaign will belong to (format: int64)
  label: string # The label of the new campaign
]: any -> record<id: int, uri: string, tracker: record<id: int, uri: string, label: string, color: string, project: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "test_selector" $test_selector "scalar") (serialize-qp "milestone_id" $milestone_id "scalar") (serialize-qp "report_id" $report_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/testmanagement_campaigns" $qp)
  let body = {project_id: $project_id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST automated tests 🔐
#
# POST /testmanagement_campaigns/{id}/automated_tests
# operationId: tuleap\TestManagement\REST\v1\CampaignsResourceCreateAutomatedTests
export def "testmanagement-campaigns-automated-tests tuleapTestManagementRESTv1CampaignsResourceCreateAutomatedTests" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_campaigns/($id)/automated_tests")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a definition 🔐
#
# GET /testmanagement_definitions/{id}
# operationId: tuleap\TestManagement\REST\v1\DefinitionsResourceRetrieveId
export def "testmanagement-definitions tuleapTestManagementRESTv1DefinitionsResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_definitions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a test execution 🔐
#
# POST /testmanagement_executions
# operationId: createTuleap\TestManagement\REST\v1\ExecutionsResource
# --tracker_reference shape: {id: int, uri?: string, label?: string, color?: string, project?: string}
export def "testmanagement-executions createTuleapTestManagementRESTv1ExecutionsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  tracker_reference: any # shape: {id: int, uri?: string, label?: string, color?: string, project?: string}
  definition_id: int # Definition of the execution (format: int64)
  status: string@status-completer-5 # Status of the execution
  --time: int # Result of the execution (format: int64)
  --results: string
]: any -> record<id: int, uri: string, results: string, status: string, last_update_date: string, assigned_to: string, previous_result: string, definition: string, linked_bugs: list<any>, time: int, steps_results: list<any>, upload_url: string, max_size_upload: int, attachments: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/testmanagement_executions")
  let body = {tracker_reference: $tracker_reference, definition_id: $definition_id, status: $status, time: $time, results: $results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# User views a test execution 🔐
#
# PATCH /testmanagement_executions/{id}/presences
# operationId: tuleap\TestManagement\REST\v1\ExecutionsResourcePresences
export def "testmanagement-executions-presences tuleapTestManagementRESTv1ExecutionsResourcePresences" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  uuid: string # Uuid of current user
  --remove-from: string # Id of the old artifact
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_executions/($id)/presences")
  let body = {uuid: $uuid, remove_from: $remove_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an artifact link between an issue and a test execution 🔐
#
# PATCH /testmanagement_executions/{id}/issues
# operationId: tuleap\TestManagement\REST\v1\ExecutionsResourceModifyIssueLink
# --comment shape: {body?: string, format: string}
export def "testmanagement-executions-issues tuleapTestManagementRESTv1ExecutionsResourceModifyIssueLink" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  issue_id: string # Id of the issue artifact
  --comment: any # shape: {body?: string, format: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_executions/($id)/issues")
  let body = {issue_id: $issue_id, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get execution 🔐
#
# GET /testmanagement_executions/{id}
# operationId: tuleap\TestManagement\REST\v1\ExecutionsResourceRetrieveId
export def "testmanagement-executions tuleapTestManagementRESTv1ExecutionsResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string, results: string, status: string, last_update_date: string, assigned_to: string, previous_result: string, definition: string, linked_bugs: list<any>, time: int, steps_results: list<any>, upload_url: string, max_size_upload: int, attachments: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_executions/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update part of a test execution 🔐
#
# PATCH /testmanagement_executions/{id}
# operationId: tuleap\TestManagement\REST\v1\ExecutionsResourceModifyId
export def "testmanagement-executions tuleapTestManagementRESTv1ExecutionsResourceModifyId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --force-use-latest-definition-version: string@bool-completer # True to update the execution to use latest version of definition
  --steps-results: list # Results of steps
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_executions/($id)")
  let body = {force_use_latest_definition_version: $force_use_latest_definition_version, steps_results: $steps_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a test execution 🔐
#
# PUT /testmanagement_executions/{id}
# operationId: tuleap\TestManagement\REST\v1\ExecutionsResourceUpdateId
export def "testmanagement-executions tuleapTestManagementRESTv1ExecutionsResourceUpdateId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  status: string@status-completer-5 # Status of the execution
  --uploaded-file-ids: list # files_ids to add during the execution
  --deleted-file-ids: list # files_ids to delete during the execution
  --time: int # Time to pass the execution (format: int64)
  --results: string # Result of the execution
]: any -> record<id: int, uri: string, results: string, status: string, last_update_date: string, assigned_to: string, previous_result: string, definition: string, linked_bugs: list<any>, time: int, steps_results: list<any>, upload_url: string, max_size_upload: int, attachments: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_executions/($id)")
  let body = {status: $status, uploaded_file_ids: $uploaded_file_ids, deleted_file_ids: $deleted_file_ids, time: $time, results: $results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a node representation /!\ EXPERIMENTAL DO NOT USE IT/!\ 🔐
#
# GET /testmanagement_nodes/{id}
# operationId: tuleap\TestManagement\REST\v1\NodeResourceRetrieveId
export def "testmanagement-nodes tuleapTestManagementRESTv1NodeResourceRetrieveId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<links: list<string>, reverse_links: list<string>, id: int, uri: string, ref_name: string, ref_label: string, color: string, title: string, url: string, status_semantic: string, status_label: string, nature: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/testmanagement_nodes/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get top-level cards ◑
#
# GET /taskboard/{id}/cards
# operationId: tuleap\Taskboard\REST\v1\TaskboardResourceRetrieveCards
export def "taskboard-cards tuleapTaskboardRESTv1TaskboardResourceRetrieveCards" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/taskboard/($id)/cards" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get columns ◑
#
# GET /taskboard/{id}/columns
# operationId: tuleap\Taskboard\REST\v1\TaskboardResourceRetrieveColumns
export def "taskboard-columns tuleapTaskboardRESTv1TaskboardResourceRetrieveColumns" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/taskboard/($id)/columns")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get card children ◑
#
# GET /taskboard_cards/{id}/children
# operationId: tuleap\Taskboard\REST\v1\TaskboardCardResourceRetrieveChildren
export def "taskboard-cards-children tuleapTaskboardRESTv1TaskboardCardResourceRetrieveChildren" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --milestone-id: int # Id of the milestone (format: int64)
  --limit: int # Number of elements per page (format: int64, default: 100)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "milestone_id" $milestone_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/taskboard_cards/($id)/children" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get card ◑
#
# GET /taskboard_cards/{id}
# operationId: tuleap\Taskboard\REST\v1\TaskboardCardResourceRetrieveId
export def "taskboard-cards tuleapTaskboardRESTv1TaskboardCardResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --milestone-id: int # Id of the milestone (format: int64)
]: nothing -> record<id: int, tracker_id: int, label: string, xref: string, rank: int, color: string, background_color: string, artifact_html_uri: string, has_children: bool, assignees: table<id: int, uri: string, user_url: string, real_name: string, display_name: string, username: string, ldap_id: string, avatar_url: string, is_anonymous: bool, has_avatar: bool>, mapped_list_value: string, initial_effort: float, remaining_effort: string, is_open: bool, is_collapsed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "milestone_id" $milestone_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/taskboard_cards/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch card 🔐
#
# PATCH /taskboard_cards/{id}
# operationId: tuleap\Taskboard\REST\v1\TaskboardCardResourceModifyId
export def "taskboard-cards tuleapTaskboardRESTv1TaskboardCardResourceModifyId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  remaining_effort: float # format: double
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/taskboard_cards/($id)")
  let body = {remaining_effort: $remaining_effort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch Taskboard cell 🔐
#
# PATCH /taskboard_cells/{swimlane_id}/column/{column_id}
# operationId: modifyTuleap\Taskboard\REST\v1\Cell\CellResource
# --order shape: {ids: list, direction: string, compared_to: int}
export def "taskboard-cells-column modifyTuleapTaskboardRESTv1CellCellResource" [
  swimlane_id: int
  column_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --add: int # | null $add (format: int64)
  --order: any # shape: {ids: list, direction: string, compared_to: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/taskboard_cells/($swimlane_id)/column/($column_id)")
  let body = {add: $add, order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get items related to a search ◑
#
# POST /search
# operationId: tuleap\FullTextSearchCommon\REST\v1\SearchResourceRetrieveSearchItems
export def "search tuleapFullTextSearchCommonRESTv1SearchResourceRetrieveSearchItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # format: int64, default: 50
  --offset: int # format: int64
  keywords: string
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let body = {keywords: $keywords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the tasks ◑
#
# GET /roadmaps/{id}/tasks
# operationId: tuleap\Roadmap\REST\v1\RoadmapResourceRetrieveTasks
export def "roadmaps-tasks tuleapRoadmapRESTv1RoadmapResourceRetrieveTasks" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Position of the first element to display (format: int64)
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roadmaps/($id)/tasks" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the iterations ◑
#
# GET /roadmaps/{id}/iterations
# operationId: tuleap\Roadmap\REST\v1\RoadmapResourceRetrieveIterations
export def "roadmaps-iterations tuleapRoadmapRESTv1RoadmapResourceRetrieveIterations" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --level: int # Level of the iteration (format: int64)
  --offset: int # Position of the first element to display (format: int64)
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roadmaps/($id)/iterations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the subtasks ◑
#
# GET /roadmap_tasks/{id}/subtasks
# operationId: tuleap\Roadmap\REST\v1\TasksResourceRetrieveSubtasks
export def "roadmap-tasks-subtasks tuleapRoadmapRESTv1TasksResourceRetrieveSubtasks" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --offset: int # Position of the first element to display (format: int64)
  --limit: int # Number of elements displayed per page (format: int64, default: 100)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roadmap_tasks/($id)/subtasks" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get kanban ◑
#
# GET /kanban/{id}
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceRetrieveId
export def "kanban TuleapKanbanRESTv1KanbanResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, tracker_id: int, tracker: string, uri: string, label: string, columns: table<id: int, label: string, is_open: bool, limit: int, color: string, user_can_add_in_place: bool, user_can_remove_column: bool, user_can_edit_label: bool>, resources: list<string>, backlog: string, archive: string, user_can_add_columns: bool, user_can_reorder_columns: bool, user_can_add_artifact: bool, is_promoted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch kanban 🔐
#
# PATCH /kanban/{id}
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceModifyId
# --collapse_column shape: {column_id: int, value: bool}
export def "kanban TuleapKanbanRESTv1KanbanResourceModifyId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --label: string # The new label
  --is-promoted: string@bool-completer # Is the kanban promoted?
  --collapse-column: any # shape: {column_id: int, value: bool}
  --collapse-archive: string@bool-completer # True to collapse the archive (save in user prefs)
  --collapse-backlog: string@bool-completer # True to collapse the backlog (save in user prefs)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)")
  let body = {label: $label, is_promoted: $is_promoted, collapse_column: $collapse_column, collapse_archive: $collapse_archive, collapse_backlog: $collapse_backlog} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Kanban 🔐
#
# DELETE /kanban/{id}
# operationId: remove\Tuleap\Kanban\REST\v1\KanbanResource
export def "kanban removeTuleapKanbanRESTv1KanbanResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get backlog ◑
#
# GET /kanban/{id}/backlog
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceRetrieveBacklog
export def "kanban-backlog TuleapKanbanRESTv1KanbanResourceRetrieveBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # Search string in json format
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<collection: string, total_size: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kanban/($id)/backlog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial re-order of Kanban backlog items 🔐
#
# PATCH /kanban/{id}/backlog
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceModifyBacklog
# --order shape: {ids: list, direction: string, compared_to: int}
# --add shape: {ids: list}
export def "kanban-backlog TuleapKanbanRESTv1KanbanResourceModifyBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --order: any # shape: {ids: list, direction: string, compared_to: int}
  --add: any # shape: {ids: list}
  --from-column: string # Id of the column the item is coming from (when moving an item)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)/backlog")
  let body = {order: $order, add: $add, from_column: $from_column} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get archive ◑
#
# GET /kanban/{id}/archive
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceRetrieveArchive
export def "kanban-archive TuleapKanbanRESTv1KanbanResourceRetrieveArchive" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # Search string in json format
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<collection: string, total_size: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kanban/($id)/archive" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial re-order of Kanban archive items 🔐
#
# PATCH /kanban/{id}/archive
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceModifyArchive
# --order shape: {ids: list, direction: string, compared_to: int}
# --add shape: {ids: list}
export def "kanban-archive TuleapKanbanRESTv1KanbanResourceModifyArchive" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --order: any # shape: {ids: list, direction: string, compared_to: int}
  --add: any # shape: {ids: list}
  --from-column: string # Id of the column the item is coming from (when moving an item)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)/archive")
  let body = {order: $order, add: $add, from_column: $from_column} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get items ◑
#
# GET /kanban/{id}/items
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceRetrieveItems
export def "kanban-items TuleapKanbanRESTv1KanbanResourceRetrieveItems" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --column-id: int # Id of the column the item belongs to (format: int64)
  --qp-query: string # Search string in json format
  --limit: int # Number of elements displayed per page (format: int64, default: 10)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> record<collection: string, total_size: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "column_id" $column_id "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kanban/($id)/items" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partial re-order of Kanban items 🔐
#
# PATCH /kanban/{id}/items
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceModifyItems
# --order shape: {ids: list, direction: string, compared_to: int}
# --add shape: {ids: list}
export def "kanban-items TuleapKanbanRESTv1KanbanResourceModifyItems" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --column-id: int # Id of the column the item belongs to (format: int64)
  --order: any # shape: {ids: list, direction: string, compared_to: int}
  --add: any # shape: {ids: list}
  --from-column: string # Id of the column the item is coming from (when moving an item)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "column_id" $column_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kanban/($id)/items" $qp)
  let body = {order: $order, add: $add, from_column: $from_column} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new column 🔐
#
# POST /kanban/{id}/columns
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceCreateColumns
export def "kanban-columns TuleapKanbanRESTv1KanbanResourceCreateColumns" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  label: string
]: any -> record<id: int, label: string, is_open: bool, limit: int, color: string, user_can_add_in_place: bool, user_can_remove_column: bool, user_can_edit_label: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)/columns")
  let body = {label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reorder Kanban columns 🔐
#
# PUT /kanban/{id}/columns
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceUpdateColumns
export def "kanban-columns TuleapKanbanRESTv1KanbanResourceUpdateColumns" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  column_ids: list # The created kanban column
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)/columns")
  let body = {column_ids: $column_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get cumulative flow ◑
#
# GET /kanban/{id}/cumulative_flow
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceRetrieveCumulativeFlow
export def "kanban-cumulative-flow TuleapKanbanRESTv1KanbanResourceRetrieveCumulativeFlow" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --start-date: string # Start date of the cumulative flow in ISO format (YYYY-MM-DD) (format: date)
  --end-date: string # End date of the cumulative flow in ISO format (YYYY-MM-DD) (format: date)
  --interval-between-point: int # Number of days between 2 points of the cumulative flow (format: int64)
  --qp-query: string # Search string in json format
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "interval_between_point" $interval_between_point "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kanban/($id)/cumulative_flow" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add list of report available for filters 🔐
#
# PUT /kanban/{id}/tracker_reports
# operationId: \Tuleap\Kanban\REST\v1\KanbanResourceUpdateTrackerReports
export def "kanban-tracker-reports TuleapKanbanRESTv1KanbanResourceUpdateTrackerReports" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  tracker_report_ids: list # List of selected report ids
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban/($id)/tracker_reports")
  let body = {tracker_report_ids: $tracker_report_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update column 🔐
#
# PATCH /kanban_columns/{id}
# operationId: modify\Tuleap\Kanban\REST\v1\KanbanColumnsResource
export def "kanban-columns modifyTuleapKanbanRESTv1KanbanColumnsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --kanban-id: int # Id of the Kanban (format: int64)
  --label: string
  --wip-limit: int # format: int64
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kanban_id" $kanban_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kanban_columns/($id)" $qp)
  let body = {label: $label, wip_limit: $wip_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete column 🔐
#
# DELETE /kanban_columns/{id}
# operationId: remove\Tuleap\Kanban\REST\v1\KanbanColumnsResource
export def "kanban-columns removeTuleapKanbanRESTv1KanbanColumnsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --kanban-id: int # Id of the Kanban (format: int64)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kanban_id" $kanban_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/kanban_columns/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add new Kanban Item 🔐
#
# POST /kanban_items
# operationId: create\Tuleap\Kanban\REST\v1\KanbanItemsResource
export def "kanban-items createTuleapKanbanRESTv1KanbanItemsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  kanban_id: int # format: int64
  label: string
  --column-id: int # format: int64
]: any -> record<id: int, item_name: string, label: string, color: string, card_fields: string, timeinfo: string, in_column: string, background_color_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kanban_items")
  let body = {kanban_id: $kanban_id, label: $label, column_id: $column_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Kanban item 🔐
#
# GET /kanban_items/{id}
# operationId: retrieve\Tuleap\Kanban\REST\v1\KanbanItemsResource
export def "kanban-items retrieveTuleapKanbanRESTv1KanbanItemsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, item_name: string, label: string, color: string, card_fields: string, timeinfo: string, in_column: string, background_color_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/kanban_items/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move an existing artidoc document ◑
#
# PATCH /artidoc/{id}
# operationId: modifyTuleap\Artidoc\REST\v1\ArtidocResource
# --move shape: {destination_folder_id: int}
export def "artidoc modifyTuleapArtidocRESTv1ArtidocResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  move: any # shape: {destination_folder_id: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artidoc/($id)")
  let body = {move: $move} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sections ◑
#
# GET /artidoc/{id}/sections
# operationId: tuleap\Artidoc\REST\v1\ArtidocResourceRetrieveSections
export def "artidoc-sections tuleapArtidocRESTv1ArtidocResourceRetrieveSections" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artidoc/($id)/sections" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder sections ◑
#
# PATCH /artidoc/{id}/sections
# operationId: tuleap\Artidoc\REST\v1\ArtidocResourceModifySections
export def "artidoc-sections tuleapArtidocRESTv1ArtidocResourceModifySections" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  ids: list # List of section identifier
  direction: string # before|after
  compared_to: string # Section identifier
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artidoc/($id)/sections")
  let body = {ids: $ids, direction: $direction, compared_to: $compared_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set configuration ◑
#
# PUT /artidoc/{id}/configuration
# operationId: tuleap\Artidoc\REST\v1\ArtidocResourceUpdateConfiguration
export def "artidoc-configuration tuleapArtidocRESTv1ArtidocResourceUpdateConfiguration" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  selected_tracker_ids: list # Selected trackers for the document
  --body-fields: list # Selected artifact fields for the document
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artidoc/($id)/configuration")
  let body = {selected_tracker_ids: $selected_tracker_ids, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get content of a section ◑
#
# GET /artidoc_sections/{id}
# operationId: retrieveTuleap\Artidoc\REST\v1\ArtidocSectionsResource
export def "artidoc-sections retrieveTuleapArtidocRESTv1ArtidocSectionsResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artidoc_sections/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update section ◑
#
# PUT /artidoc_sections/{id}
# operationId: updateTuleap\Artidoc\REST\v1\ArtidocSectionsResource
export def "artidoc-sections updateTuleapArtidocRESTv1ArtidocSectionsResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --description: string
  title: string
  attachments: list
  level: int # format: int64
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artidoc_sections/($id)")
  let body = {description: $description, title: $title, attachments: $attachments, level: $level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete section ◑
#
# DELETE /artidoc_sections/{id}
# operationId: removeTuleap\Artidoc\REST\v1\ArtidocSectionsResource
export def "artidoc-sections removeTuleapArtidocRESTv1ArtidocSectionsResource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artidoc_sections/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create section ◑
#
# POST /artidoc_sections
# operationId: tuleap\Artidoc\REST\v1\ArtidocSectionsResourceCreateSection
# --section shape: {import?: any, content?: any, position?: any}
export def "artidoc-sections tuleapArtidocRESTv1ArtidocSectionsResourceCreateSection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  artidoc_id: int # Id of the document (format: int64)
  section: any # shape: {import?: any, content?: any, position?: any}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/artidoc_sections")
  let body = {artidoc_id: $artidoc_id, section: $section} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create file 🔐
#
# POST /artidoc_files
# operationId: createTuleap\Artidoc\REST\v1\ArtidocFilesResource
export def "artidoc-files createTuleapArtidocRESTv1ArtidocFilesResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  artidoc_id: int # The id of the document (format: int64)
  name: string # The file name
  file_size: int # The file size (format: int64)
  file_type: string # The file type
]: any -> record<id: string, download_href: string, upload_href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/artidoc_files")
  let body = {artidoc_id: $artidoc_id, name: $name, file_size: $file_size, file_type: $file_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Baseline 🔐
#
# POST /baselines
# operationId: create\Tuleap\Baseline\REST\BaselinesResource
export def "baselines createTuleapBaselineRESTBaselinesResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # Name of the baseline
  artifact_id: int # Id of an artifact (format: int64)
  --snapshot-date: string # Snapshot date of the baseline
]: any -> record<id: string, name: string, artifact_id: string, snapshot_date: string, author_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/baselines")
  let body = {name: $name, artifact_id: $artifact_id, snapshot_date: $snapshot_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Baseline 🔐
#
# DELETE /baselines/{id}
# operationId: remove\Tuleap\Baseline\REST\BaselinesResource
export def "baselines removeTuleapBaselineRESTBaselinesResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baselines/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Baseline ◑
#
# GET /baselines/{id}
# operationId: \Tuleap\Baseline\REST\BaselinesResourceRetrieveById
export def "baselines TuleapBaselineRESTBaselinesResourceRetrieveById" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, artifact_id: string, snapshot_date: string, author_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baselines/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get artifacts ◑
#
# GET /baselines/{id}/artifacts
# operationId: tuleap\Baseline\REST\BaselineArtifactsResourceRetrieveBaselines
export def "baselines-artifacts tuleapBaselineRESTBaselineArtifactsResourceRetrieveBaselines" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # JSON object of search criteria properties
]: nothing -> record<artifacts: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/baselines/($id)/artifacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new baseline comparison. 🔐
#
# POST /baselines_comparisons
# operationId: createTuleap\Baseline\REST\ComparisonsResource
export def "baselines-comparisons createTuleapBaselineRESTComparisonsResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  base_baseline_id: int # Id of the baseline used as base comparison (format: int64)
  compared_to_baseline_id: int # Id of the baseline to be compared (format: int64)
  --name: string # Name of the comparison
  --comment: string # Comment
]: any -> record<id: string, name: string, comment: string, base_baseline_id: string, compared_to_baseline_id: string, author_id: string, creation_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/baselines_comparisons")
  let body = {base_baseline_id: $base_baseline_id, compared_to_baseline_id: $compared_to_baseline_id, name: $name, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Comparison ◑
#
# GET /baselines_comparisons/{id}
# operationId: tuleap\Baseline\REST\ComparisonsResourceRetrieveById
export def "baselines-comparisons tuleapBaselineRESTComparisonsResourceRetrieveById" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, comment: string, base_baseline_id: string, compared_to_baseline_id: string, author_id: string, creation_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baselines_comparisons/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Comparison 🔐
#
# DELETE /baselines_comparisons/{id}
# operationId: removeTuleap\Baseline\REST\ComparisonsResource
export def "baselines-comparisons removeTuleapBaselineRESTComparisonsResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baselines_comparisons/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Integrate a GitLab repository into a project. 🔐
#
# POST /gitlab_repositories
# operationId: tuleap\Gitlab\REST\v1\GitlabRepositoryResourceCreateGitlabRepository
export def "gitlab-repositories tuleapGitlabRESTv1GitlabRepositoryResourceCreateGitlabRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  project_id: int # format: int64
  gitlab_server_url: string
  gitlab_bot_api_token: string
  gitlab_repository_id: int # format: int64
  --allow-artifact-closure: string@bool-completer
]: any -> record<id: int, gitlab_repository_id: int, name: string, description: string, gitlab_repository_url: string, last_push_date: string, project: string, allow_artifact_closure: bool, is_webhook_configured: bool, create_branch_prefix: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gitlab_repositories")
  let body = {project_id: $project_id, gitlab_server_url: $gitlab_server_url, gitlab_bot_api_token: $gitlab_bot_api_token, gitlab_repository_id: $gitlab_repository_id, allow_artifact_closure: $allow_artifact_closure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Gitlab Integrations. 🔐
#
# DELETE /gitlab_repositories/{id}
# operationId: tuleap\Gitlab\REST\v1\GitlabRepositoryResourceRemoveGitlabRepository
export def "gitlab-repositories tuleapGitlabRESTv1GitlabRepositoryResourceRemoveGitlabRepository" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gitlab_repositories/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update GitLab integration 🔐
#
# PATCH /gitlab_repositories/{id}
# operationId: tuleap\Gitlab\REST\v1\GitlabRepositoryResourceModifyId
# --update_bot_api_token shape: {gitlab_api_token: string}
export def "gitlab-repositories tuleapGitlabRESTv1GitlabRepositoryResourceModifyId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --update-bot-api-token: any # shape: {gitlab_api_token: string}
  --generate-new-secret: string@bool-completer # | null
  --allow-artifact-closure: string@bool-completer # | null
  --create-branch-prefix: string # | null
]: any -> record<id: int, gitlab_repository_id: int, name: string, description: string, gitlab_repository_url: string, last_push_date: string, project: string, allow_artifact_closure: bool, is_webhook_configured: bool, create_branch_prefix: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gitlab_repositories/($id)")
  let body = {update_bot_api_token: $update_bot_api_token, generate_new_secret: $generate_new_secret, allow_artifact_closure: $allow_artifact_closure, create_branch_prefix: $create_branch_prefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information on branches of the GitLab repository 🔐
#
# GET /gitlab_repositories/{id}/branches
# operationId: tuleap\Gitlab\REST\v1\GitlabRepositoryResourceRetrieveBranches
export def "gitlab-repositories-branches tuleapGitlabRESTv1GitlabRepositoryResourceRetrieveBranches" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<default_branch: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gitlab_repositories/($id)/branches")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a GitLab branch. 🔐
#
# POST /gitlab_branch
# operationId: tuleap\Gitlab\REST\v1\GitlabBranchResourceCreateGitlabBranch
export def "gitlab-branch tuleapGitlabRESTv1GitlabBranchResourceCreateGitlabBranch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  gitlab_integration_id: int # format: int64
  artifact_id: int # format: int64
  reference: string
]: any -> record<branch_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gitlab_branch")
  let body = {gitlab_integration_id: $gitlab_integration_id, artifact_id: $artifact_id, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a GitLab merge request. 🔐
#
# POST /gitlab_merge_request
# operationId: tuleap\Gitlab\REST\v1\GitlabMergeRequestResourceCreateGitlabMergeRequest
export def "gitlab-merge-request tuleapGitlabRESTv1GitlabMergeRequestResourceCreateGitlabMergeRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  gitlab_integration_id: int # format: int64
  artifact_id: int # format: int64
  source_branch: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gitlab_merge_request")
  let body = {gitlab_integration_id: $gitlab_integration_id, artifact_id: $artifact_id, source_branch: $source_branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Link a GitLab group to a Tuleap project. 🔐
#
# POST /gitlab_groups
# operationId: tuleap\Gitlab\REST\v1\GitlabGroupResourceCreateGroup
export def "gitlab-groups tuleapGitlabRESTv1GitlabGroupResourceCreateGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  gitlab_server_url: string
  --create-branch-prefix: string # | null $create_branch_prefix
  project_id: int # format: int64
  gitlab_group_id: int # format: int64
  gitlab_token: string
  --allow-artifact-closure: string@bool-completer
]: any -> record<id: int, number_of_integrations: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gitlab_groups")
  let body = {gitlab_server_url: $gitlab_server_url, create_branch_prefix: $create_branch_prefix, project_id: $project_id, gitlab_group_id: $gitlab_group_id, gitlab_token: $gitlab_token, allow_artifact_closure: $allow_artifact_closure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a GitLab group linked with Tuleap. 🔐
#
# PATCH /gitlab_groups/{id}
# operationId: tuleap\Gitlab\REST\v1\GitlabGroupResourceUpdateGroupLink
export def "gitlab-groups tuleapGitlabRESTv1GitlabGroupResourceUpdateGroupLink" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --create-branch-prefix: string # | null
  --allow-artifact-closure: string@bool-completer # | null
  --gitlab-token: string # | null
]: any -> record<last_synchronization_date: string, id: int, gitlab_group_id: int, project_id: int, name: string, full_path: string, web_url: string, avatar_url: string, allow_artifact_closure: bool, create_branch_prefix: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gitlab_groups/($id)")
  let body = {create_branch_prefix: $create_branch_prefix, allow_artifact_closure: $allow_artifact_closure, gitlab_token: $gitlab_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlink the Tuleap Project and the GitLab group. 🔐
#
# DELETE /gitlab_groups/{id}
# operationId: tuleap\Gitlab\REST\v1\GitlabGroupResourceRemoveGroupLink
export def "gitlab-groups tuleapGitlabRESTv1GitlabGroupResourceRemoveGroupLink" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gitlab_groups/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Synchronize GitLab projects of a group with Tuleap 🔐
#
# POST /gitlab_groups/{id}/synchronize
# operationId: tuleap\Gitlab\REST\v1\GitlabGroupResourceCreateSynchronizeGroupLink
export def "gitlab-groups-synchronize tuleapGitlabRESTv1GitlabGroupResourceCreateSynchronizeGroupLink" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, number_of_integrations: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gitlab_groups/($id)/synchronize")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get content of a program increment ◑
#
# GET /program_increment/{id}/content
# operationId: tuleap\ProgramManagement\REST\v1\ProgramIncrementResourceRetrieveContent
export def "program-increment-content tuleapProgramManagementRESTv1ProgramIncrementResourceRetrieveContent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/program_increment/($id)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change the program increment's contents 🔐
#
# PATCH /program_increment/{id}/content
# operationId: tuleap\ProgramManagement\REST\v1\ProgramIncrementResourceModifyContent
# --order shape: {ids: list, direction: "after"|"before", compared_to: int}
export def "program-increment-content tuleapProgramManagementRESTv1ProgramIncrementResourceModifyContent" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  add: list
  --order: any # shape: {ids: list, direction: "after"|"before", compared_to: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/program_increment/($id)/content")
  let body = {add: $add, order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get iterations linked to a program increment ◑
#
# GET /program_increment/{id}/iterations
# operationId: tuleap\ProgramManagement\REST\v1\ProgramIncrementResourceRetrieveIterations
export def "program-increment-iterations tuleapProgramManagementRESTv1ProgramIncrementResourceRetrieveIterations" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/program_increment/($id)/iterations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the backlog of the program increment ◑
#
# GET /program_increment/{id}/backlog
# operationId: tuleap\ProgramManagement\REST\v1\ProgramIncrementResourceRetrieveBacklog
export def "program-increment-backlog tuleapProgramManagementRESTv1ProgramIncrementResourceRetrieveBacklog" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/program_increment/($id)/backlog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get content of a feature ◑
#
# GET /program_backlog_items/{id}/children
# operationId: tuleap\ProgramManagement\REST\v1\ProgramBacklogItemsResourceRetrieveChildren
export def "program-backlog-items-children tuleapProgramManagementRESTv1ProgramBacklogItemsResourceRetrieveChildren" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/program_backlog_items/($id)/children" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the user stories linked to an iteration in team projects ◑
#
# GET /iteration/{id}/content
# operationId: tuleap\ProgramManagement\REST\v1\IterationResourceRetrieveIterations
export def "iteration-content tuleapProgramManagementRESTv1IterationResourceRetrieveIterations" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of elements displayed per page (format: int64, default: 50)
  --offset: int # Position of the first element to display (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/iteration/($id)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve time recorded on something 🔐
#
# GET /timetracking
# operationId: tuleap\Timetracking\REST\v1\TimetrackingResourceRetrieveTrackedTimeOnArtifact
export def "timetracking tuleapTimetrackingRESTv1TimetrackingResourceRetrieveTrackedTimeOnArtifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # A query
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timetracking" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a Time 🔐
#
# POST /timetracking
# operationId: tuleap\Timetracking\REST\v1\TimetrackingResourceAddTime
export def "timetracking tuleapTimetrackingRESTv1TimetrackingResourceAddTime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  date_time: string
  artifact_id: int # format: int64
  time_value: string
  --step: string
]: any -> record<artifact: string, project: string, date: string, minutes: int, id: int, step: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timetracking")
  let body = {date_time: $date_time, artifact_id: $artifact_id, time_value: $time_value, step: $step} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Time 🔐
#
# PUT /timetracking/{id}
# operationId: tuleap\Timetracking\REST\v1\TimetrackingResourceUpdateTime
export def "timetracking tuleapTimetrackingRESTv1TimetrackingResourceUpdateTime" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  date_time: string
  time_value: string
  --step: string
]: any -> record<artifact: string, project: string, date: string, minutes: int, id: int, step: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/timetracking/($id)")
  let body = {date_time: $date_time, time_value: $time_value, step: $step} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete time 🔐
#
# DELETE /timetracking/{id}
# operationId: removeTuleap\Timetracking\REST\v1\TimetrackingResource
export def "timetracking removeTuleapTimetrackingRESTv1TimetrackingResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/timetracking/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get timetracking report 🔐
#
# GET /timetracking_reports/{id}
# operationId: tuleap\Timetracking\REST\v1\TimetrackingReportResourceRetrieveId
export def "timetracking-reports tuleapTimetrackingRESTv1TimetrackingReportResourceRetrieveId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string, trackers: list<any>, invalid_trackers: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/timetracking_reports/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a timetracking report 🔐
#
# PUT /timetracking_reports/{id}
# operationId: updateTuleap\Timetracking\REST\v1\TimetrackingReportResource
export def "timetracking-reports updateTuleapTimetrackingRESTv1TimetrackingReportResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  trackers_id: list # Tracker id to link to report
]: any -> record<id: int, uri: string, trackers: list<any>, invalid_trackers: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/timetracking_reports/($id)")
  let body = {trackers_id: $trackers_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get times of the report's trackers 🔐
#
# GET /timetracking_reports/{id}/times
# operationId: tuleap\Timetracking\REST\v1\TimetrackingReportResourceRetrieveIdTimes
export def "timetracking-reports-times tuleapTimetrackingRESTv1TimetrackingReportResourceRetrieveIdTimes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # With a property "trackers_id","start_date" and "end_date" to search trackers' times.
  --limit: int # format: int64, default: 50
  --offset: int # format: int64
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/timetracking_reports/($id)/times" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create widget 🔐
#
# POST /timetracking_people_widget
# operationId: createTuleap\Timetracking\REST\v1\PeopleTimetracking\PeopleTimetrackingWidgetResource
export def "timetracking-people-widget createTuleapTimetrackingRESTv1PeopleTimetrackingPeopleTimetrackingWidgetResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  dashboard_id: int # The id of the dashboard (format: int64)
  dashboard_type: string@dashboard-type-completer # The type of the dashboard
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timetracking_people_widget")
  let body = {dashboard_id: $dashboard_id, dashboard_type: $dashboard_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a widget 🔐
#
# PUT /timetracking_people_widget/{id}
# operationId: updateTuleap\Timetracking\REST\v1\PeopleTimetracking\PeopleTimetrackingWidgetResource
export def "timetracking-people-widget updateTuleapTimetrackingRESTv1PeopleTimetrackingPeopleTimetrackingWidgetResource" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --start-date: string # | null $start_date
  --end-date: string # | null $end_date
  --predefined-time-period: string@predefined-time-period-completer # | null $predefined_time_period
  --users: list # $users
]: any -> record<viewable_users: list<string>, no_more_viewable_users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/timetracking_people_widget/($id)")
  let body = {start_date: $start_date, end_date: $end_date, predefined_time_period: $predefined_time_period, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get times 🔐
#
# GET /timetracking_people_widget/{id}/times
# operationId: tuleap\Timetracking\REST\v1\PeopleTimetracking\PeopleTimetrackingWidgetResourceRetrieveTimes
export def "timetracking-people-widget-times tuleapTimetrackingRESTv1PeopleTimetrackingPeopleTimetrackingWidgetResourceRetrieveTimes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --limit: int # Number of users displayed per page (format: int64, default: 50)
  --offset: int # Position of the first user to display (format: int64)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/timetracking_people_widget/($id)/times" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users 🔐
#
# GET /timetracking_people_users
# operationId: retrieveTuleap\Timetracking\REST\v1\PeopleTimetracking\PeopleTimetrackingUsersResource
export def "timetracking-people-users retrieveTuleapTimetrackingRESTv1PeopleTimetrackingPeopleTimetrackingUsersResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --qp-query: string # Search string (3 chars min in length)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-accesskey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timetracking_people_users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
