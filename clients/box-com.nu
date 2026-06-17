# Auto-generated client for Box Platform API v2.0.0
# Source: https://api.apis.guru/v2/specs/box.com/2.0.0/openapi.json
# Auth: --token flag or $env.BOX_PLATFORM_API_TOKEN

const BASE_URL = "https://api.box.com/2.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BOX_PLATFORM_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.box.com/2.0" "https://account.box.com/api/oauth2" "https://upload.box.com/api/2.0" "https://api.box.com" "https://dl.boxcloud.com/2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def response-type-completer [] { ["code"] }
def direction-completer [] { ["both" "inbound" "outbound"] }
def status-completer [] { ["pending"] }
def role-completer [] { ["co-owner" "editor" "previewer" "previewer uploader" "uploader" "viewer" "viewer uploader"] }
def role-completer-1 [] { ["co-owner" "editor" "owner" "previewer" "previewer uploader" "uploader" "viewer" "viewer uploader"] }
def status-completer-1 [] { ["accepted" "pending" "rejected"] }
def direction-completer-1 [] { ["ASC" "DESC"] }
def stream-type-completer [] { ["admin_logs" "admin_logs_streaming" "all" "changes" "sync"] }
def status-completer-2 [] { ["active" "inactive"] }
def disposition-action-completer [] { ["permanently_delete" "remove_retention"] }
def accept-completer [] { ["application/json" "image/jpg" "image/png"] }
def type-completer [] { ["file_version"] }
def sync-state-completer [] { ["not_synced" "partially_synced" "synced"] }
def sort-completer [] { ["date" "id" "name" "size"] }
def role-completer-2 [] { ["admin" "member"] }
def invitability-level-completer [] { ["admins_and_members" "admins_only" "all_managed_users"] }
def member-viewability-level-completer [] { ["admins_and_members" "admins_only" "all_managed_users"] }
def assign-to-type-completer [] { ["file" "file_version" "folder" "user"] }
def scope-completer [] { ["enterprise" "global"] }
def conflict-resolution-completer [] { ["none" "overwrite"] }
def display-name-completer [] { ["Classification"] }
def scope-completer-1 [] { ["enterprise"] }
def template-key-completer [] { ["securityClassification-6VMVochwUWo"] }
def actor-token-type-completer [] { ["urn:ietf:params:oauth:token-type:id_token"] }
def box-subject-type-completer [] { ["enterprise" "user"] }
def grant-type-completer [] { ["authorization_code" "client_credentials" "refresh_token" "urn:ietf:params:oauth:grant-type:jwt-bearer" "urn:ietf:params:oauth:grant-type:token-exchange"] }
def subject-token-type-completer [] { ["urn:ietf:params:oauth:token-type:access_token"] }
def grant-type-completer-1 [] { ["refresh_token"] }
def policy-type-completer [] { ["finite" "indefinite"] }
def are-owners-notified-completer [] { ["false" "true"] }
def can-owner-extend-retention-completer [] { ["false" "true"] }
def retention-type-completer [] { ["modifiable" "non-modifiable"] }
def type-completer-1 [] { ["enterprise" "folder" "metadata_template"] }
def scope-completer-2 [] { ["enterprise_content" "user_content"] }
def type-completer-2 [] { ["file" "folder" "web_link"] }
def trash-content-completer [] { ["non_trashed_only" "trashed_only"] }
def sort-completer-1 [] { ["modified_at" "relevance"] }
def type-completer-3 [] { ["shield_information_barrier_segment_member"] }
def type-completer-4 [] { ["shield_information_barrier_segment_restriction"] }
def status-completer-3 [] { ["disabled" "draft" "enabled" "invalid" "pending"] }
def type-completer-5 [] { ["shield_information_barrier"] }
def status-completer-4 [] { ["disabled" "pending"] }
def signature-color-completer [] { ["black" "blue" "red"] }
def status-completer-5 [] { ["invoked" "permanent_failure" "processing" "success" "transient_failure"] }
def resolved-for-type-completer [] { ["enterprise" "user"] }
def resolution-state-completer [] { ["approved" "completed" "incomplete" "rejected"] }
def action-completer [] { ["complete" "review"] }
def completion-rule-completer [] { ["all_assignees" "any_assignee"] }
def tos-type-completer [] { ["external" "managed"] }
def status-completer-6 [] { ["disabled" "enabled"] }
def user-type-completer [] { ["all" "external" "managed"] }
def role-completer-3 [] { ["coadmin" "user"] }
def status-completer-7 [] { ["active" "cannot_delete_edit" "cannot_delete_edit_upload" "inactive"] }
def accept-completer-1 [] { ["application/json" "image/jpg"] }
def type-completer-6 [] { ["workflow_parameters"] }
def accept-completer-2 [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authorize get" } } | get name | first)
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

# Authorize user
#
# GET /authorize
# operationId: get_authorize
export def "authorize get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string@response-type-completer # The type of response we'd like to receive. (format: token, e.g. code)
  --client-id: string # The Client ID of the application that is requesting to authenticate the user. To get the Client ID for your application, log in to your Box developer console and click the **Edit Application** link for the application you're working with. In the OAuth 2.0 Parameters section of the configuration page, find the item labelled `client_id`. The text of that item is your application's Client ID. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --redirect-uri: string # The URI to which Box redirects the browser after the user has granted or denied the application permission. This URI match one of the redirect URIs in the configuration of your application. It must be a valid HTTPS URI and it needs to be able to handle the redirection to complete the next step in the OAuth 2.0 flow. Although this parameter is optional, it must be a part of the authorization URL if you configured multiple redirect URIs for the application in the developer console. A missing parameter causes a `redirect_uri_missing` error after the user grants application access. (format: url, e.g. http://example.com/auth/callback)
  --state: string # A custom string of your choice. Box will pass the same string to the redirect URL when authentication is complete. This parameter can be used to identify a user on redirect, as well as protect against hijacked sessions and other exploits. (e.g. my_state)
  --scope: string # A comma-separated list of application scopes you'd like to authenticate the user for. This defaults to all the scopes configured for the application in its configuration page. (e.g. admin_readwrite)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://account.box.com/api/oauth2")
  let qp = [(serialize-qp "response_type" $response_type "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorize" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List allowed collaboration domains
#
# GET /collaboration_whitelist_entries
# operationId: get_collaboration_whitelist_entries
export def "collaboration-whitelist-entries entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaboration_whitelist_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add domain to list of allowed collaboration domains
#
# POST /collaboration_whitelist_entries
# operationId: post_collaboration_whitelist_entries
export def "collaboration-whitelist-entries entries-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  direction: string@direction-completer # The direction in which to allow collaborations. (e.g. inbound)
  domain: string # The domain to add to the list of allowed domains. (e.g. example.com)
]: any -> record<created_at: string, direction: string, domain: string, enterprise: record<id: string, name: string, type: string>, id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaboration_whitelist_entries")
  let body = {"direction": $direction, "domain": $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove domain from list of allowed collaboration domains
#
# DELETE /collaboration_whitelist_entries/{collaboration_whitelist_entry_id}
# operationId: delete_collaboration_whitelist_entries_id
export def "collaboration-whitelist-entries id-by-collaboration_whitelist_entry_id" [
  collaboration_whitelist_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collaboration_whitelist_entry_id: $collaboration_whitelist_entry_id} | format pattern "/collaboration_whitelist_entries/{collaboration_whitelist_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get allowed collaboration domain
#
# GET /collaboration_whitelist_entries/{collaboration_whitelist_entry_id}
# operationId: get_collaboration_whitelist_entries_id
export def "collaboration-whitelist-entries id-by-collaboration_whitelist_entry_id-1" [
  collaboration_whitelist_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, direction: string, domain: string, enterprise: record<id: string, name: string, type: string>, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collaboration_whitelist_entry_id: $collaboration_whitelist_entry_id} | format pattern "/collaboration_whitelist_entries/{collaboration_whitelist_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users exempt from collaboration domain restrictions
#
# GET /collaboration_whitelist_exempt_targets
# operationId: get_collaboration_whitelist_exempt_targets
export def "collaboration-whitelist-exempt-targets targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaboration_whitelist_exempt_targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create user exemption from collaboration domain restrictions
#
# POST /collaboration_whitelist_exempt_targets
# operationId: post_collaboration_whitelist_exempt_targets
# --user shape: {id: string}
export def "collaboration-whitelist-exempt-targets targets-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # The user to exempt. — shape: {id: string}
]: any -> record<created_at: string, enterprise: record<id: string, name: string, type: string>, id: string, modified_at: string, type: string, user: record<id: string, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaboration_whitelist_exempt_targets")
  let body = {"user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove user from list of users exempt from domain restrictions
#
# DELETE /collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}
# operationId: delete_collaboration_whitelist_exempt_targets_id
export def "collaboration-whitelist-exempt-targets id-by-collaboration_whitelist_exempt_target_id" [
  collaboration_whitelist_exempt_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collaboration_whitelist_exempt_target_id: $collaboration_whitelist_exempt_target_id} | format pattern "/collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user exempt from collaboration domain restrictions
#
# GET /collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}
# operationId: get_collaboration_whitelist_exempt_targets_id
export def "collaboration-whitelist-exempt-targets id-by-collaboration_whitelist_exempt_target_id-1" [
  collaboration_whitelist_exempt_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, enterprise: record<id: string, name: string, type: string>, id: string, modified_at: string, type: string, user: record<id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collaboration_whitelist_exempt_target_id: $collaboration_whitelist_exempt_target_id} | format pattern "/collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pending collaborations
#
# GET /collaborations
# operationId: get_collaborations
export def "collaborations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The status of the collaborations to retrieve (e.g. pending)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaborations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create collaboration
#
# POST /collaborations
# operationId: post_collaborations
# --accessible_by shape: {id?: string, login?: string, type: "user"|"group"}
# --item shape: {id: string, type: "file"|"folder"}
export def "collaborations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --notify: oneof<nothing, bool> # Determines if users should receive email notification for the action performed. (e.g. true)
  accessible_by: record # The user or group to give access to the item. — shape: {id?: string, login?: string, type: "user"|"group"}
  --can-view-path: oneof<nothing, bool> # Determines if the invited users can see the entire parent path to the associated folder. The user will not gain privileges in any parent folder and therefore can not see content the user is not collaborated on.  Be aware that this meaningfully increases the time required to load the invitee's **All Files** page. We recommend you limit the number of collaborations with `can_view_path` enabled to 1,000 per user.  Only owner or co-owners can invite collaborators with a `can_view_path` of `true`.  `can_view_path` can only be used for folder collaborations. (e.g. true)
  --expires-at: string # Set the expiration date for the collaboration. At this date, the collaboration will be automatically removed from the item.  This feature will only work if the **Automatically remove invited collaborators: Allow folder owners to extend the expiry date** setting has been enabled in the **Enterprise Settings** of the **Admin Console**. When the setting is not enabled, collaborations can not have an expiry date and a value for this field will be result in an error. (format: date-time, e.g. 2019-08-29T23:59:00-07:00)
  item: record # The item to attach the comment to. — shape: {id: string, type: "file"|"folder"}
  role: string@role-completer # The level of access granted. (e.g. editor)
]: any -> record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaborations" $qp)
  let body = {"accessible_by": $accessible_by, "can_view_path": $can_view_path, "expires_at": $expires_at, "item": $item, "role": $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove collaboration
#
# DELETE /collaborations/{collaboration_id}
# operationId: delete_collaborations_id
export def "collaborations id-by-collaboration_id" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collaboration_id: $collaboration_id} | format pattern "/collaborations/{collaboration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get collaboration
#
# GET /collaborations/{collaboration_id}
# operationId: get_collaborations_id
export def "collaborations id-by-collaboration_id-1" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({collaboration_id: $collaboration_id} | format pattern "/collaborations/{collaboration_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update collaboration
#
# PUT /collaborations/{collaboration_id}
# operationId: put_collaborations_id
export def "collaborations id-by-collaboration_id-2" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --can-view-path: oneof<nothing, bool> # Determines if the invited users can see the entire parent path to the associated folder. The user will not gain privileges in any parent folder and therefore can not see content the user is not collaborated on.  Be aware that this meaningfully increases the time required to load the invitee's **All Files** page. We recommend you limit the number of collaborations with `can_view_path` enabled to 1,000 per user.  Only owner or co-owners can invite collaborators with a `can_view_path` of `true`.  `can_view_path` can only be used for folder collaborations. (e.g. true)
  --expires-at: string # Update the expiration date for the collaboration. At this date, the collaboration will be automatically removed from the item.  This feature will only work if the **Automatically remove invited collaborators: Allow folder owners to extend the expiry date** setting has been enabled in the **Enterprise Settings** of the **Admin Console**. When the setting is not enabled, collaborations can not have an expiry date and a value for this field will be result in an error.  Additionally, a collaboration can only be given an expiration if it was created after the **Automatically remove invited collaborator** setting was enabled. (format: date-time, e.g. 2019-08-29T23:59:00-07:00)
  role: string@role-completer-1 # The level of access granted. (e.g. editor)
  --status: string@status-completer-1 # <!--alex ignore reject--> Set the status of a `pending` collaboration invitation, effectively accepting, or rejecting the invite. (e.g. accepted)
]: any -> record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collaboration_id: $collaboration_id} | format pattern "/collaborations/{collaboration_id}"))
  let body = {"can_view_path": $can_view_path, "expires_at": $expires_at, "role": $role, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all collections
#
# GET /collections
# operationId: get_collections
export def "collections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List collection items
#
# GET /collections/{collection_id}/items
# operationId: get_collections_id_items
export def "collections-items items" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: $collection_id} | format pattern "/collections/{collection_id}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create comment
#
# POST /comments
# operationId: post_comments
# --item shape: {id: string, type: "file"|"comment"}
export def "comments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --item: record # The item to attach the comment to. — shape: {id: string, type: "file"|"comment"}
  message: string # The text of the comment.  To mention a user, use the `tagged_message` parameter instead. (e.g. Review completed!)
  --tagged-message: string # The text of the comment, including `@[user_id:name]` somewhere in the message to mention another user, which will send them an email notification, letting them know they have been mentioned.  The `user_id` is the target user's ID, where the `name` can be any custom phrase. In the Box UI this name will link to the user's profile.  If you are not mentioning another user, use `message` instead. (e.g. @[1234:John] Review completed!)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/comments" $qp)
  let body = {"item": $item, "message": $message, "tagged_message": $tagged_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove comment
#
# DELETE /comments/{comment_id}
# operationId: delete_comments_id
export def "comments id-by-comment_id" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({comment_id: $comment_id} | format pattern "/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comment
#
# GET /comments/{comment_id}
# operationId: get_comments_id
export def "comments id-by-comment_id-1" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({comment_id: $comment_id} | format pattern "/comments/{comment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update comment
#
# PUT /comments/{comment_id}
# operationId: put_comments_id
export def "comments id-by-comment_id-2" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --message: string # The text of the comment to update (e.g. Review completed!)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({comment_id: $comment_id} | format pattern "/comments/{comment_id}") $qp)
  let body = {"message": $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove device pin
#
# DELETE /device_pinners/{device_pinner_id}
# operationId: delete_device_pinners_id
export def "device-pinners id-by-device_pinner_id" [
  device_pinner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_pinner_id: $device_pinner_id} | format pattern "/device_pinners/{device_pinner_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get device pin
#
# GET /device_pinners/{device_pinner_id}
# operationId: get_device_pinners_id
export def "device-pinners id-by-device_pinner_id-1" [
  device_pinner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, owned_by: record, product_name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_pinner_id: $device_pinner_id} | format pattern "/device_pinners/{device_pinner_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List enterprise device pins
#
# GET /enterprises/{enterprise_id}/device_pinners
# operationId: get_enterprises_id_device_pinners
export def "enterprises-device-pinners pinners" [
  enterprise_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --direction: string@direction-completer-1 # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
]: nothing -> record<entries: table<id: string, owned_by: record, product_name: string, type: string>, limit: int, next_marker: int, order: table<by: string, direction: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({enterprise_id: $enterprise_id} | format pattern "/enterprises/{enterprise_id}/device_pinners") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List user and enterprise events
#
# GET /events
# operationId: get_events
export def "events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream-type: string@stream-type-completer # Defines the type of events that are returned  * `all` returns everything for a user and is the default * `changes` returns events that may cause file tree changes   such as file updates or collaborations. * `sync` is similar to `changes` but only applies to synced folders * `admin_logs` returns all events for an entire enterprise and   requires the user making the API call to have admin permissions. This   stream type is for programmatically pulling from a 1 year history of   events across all users within the enterprise and within a   `created_after` and `created_before` time frame. The complete history   of events will be returned in chronological order based on the event   time, but latency will be much higher than `admin_logs_streaming`. * `admin_logs_streaming` returns all events for an entire enterprise and   requires the user making the API call to have admin permissions. This   stream type is for polling for recent events across all users within   the enterprise. Latency will be much lower than `admin_logs`, but   events will not be returned in chronological order and may   contain duplicates. (default: all, e.g. all)
  --stream-position: string # The location in the event stream to start receiving events from.  * `now` will return an empty list events and the latest stream position for initialization. * `0` or `null` will return all events. (e.g. 1348790499819)
  --limit: int # Limits the number of events returned  Note: Sometimes, the events less than the limit requested can be returned even when there may be more events remaining. This is primarily done in the case where a number of events have already been retrieved and these retrieved events are returned rather than delaying for an unknown amount of time to see if there are any more results. (format: int64, default: 100, e.g. 50)
  --event-type: list # A comma-separated list of events to filter by. This can only be used when requesting the events with a `stream_type` of `admin_logs` or `adming_logs_streaming`. For any other `stream_type` this value will be ignored. (e.g. [ACCESS_GRANTED])
  --created-after: string # The lower bound date and time to return events for. This can only be used when requesting the events with a `stream_type` of `admin_logs`. For any other `stream_type` this value will be ignored. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --created-before: string # The upper bound date and time to return events for. This can only be used when requesting the events with a `stream_type` of `admin_logs`. For any other `stream_type` this value will be ignored. (format: date-time, e.g. 2013-12-12T10:53:43-08:00)
]: nothing -> record<chunk_size: int, entries: table<additional_details: record, created_at: string, created_by: record, event_id: string, event_type: record, recorded_at: string, session_id: string, source: record, type: string>, next_stream_position: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream_type" $stream_type "scalar") (serialize-qp "stream_position" $stream_position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "event_type" $event_type "csv") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get events long poll endpoint
#
# OPTIONS /events
# operationId: options_events
export def "events options" [
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
  let full_url = (build-url $base "/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete file request
#
# DELETE /file_requests/{file_request_id}
# operationId: delete_file_requests_id
export def "file-requests id-by-file_request_id" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_request_id: $file_request_id} | format pattern "/file_requests/{file_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file request
#
# GET /file_requests/{file_request_id}
# operationId: get_file_requests_id
export def "file-requests id-by-file_request_id-1" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, created_by: record, description: string, etag: string, expires_at: string, folder: record, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_request_id: $file_request_id} | format pattern "/file_requests/{file_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update file request
#
# PUT /file_requests/{file_request_id}
# operationId: put_file_requests_id
export def "file-requests id-by-file_request_id-2" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --description: string # An optional new description for the file request. This can be used to change the description of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
  --expires-at: string # The date after which a file request will no longer accept new submissions.  After this date, the `status` will automatically be set to `inactive`.  This will default to the value on the existing file request. (format: date-time, e.g. 2020-09-28T10:53:43-08:00)
  --is-description-required: oneof<nothing, bool> # Whether a file request submitter is required to provide a description of the files they are submitting.  When this setting is set to true, the Box UI will show a description field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --is-email-required: oneof<nothing, bool> # Whether a file request submitter is required to provide their email address.  When this setting is set to true, the Box UI will show an email field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --status: string@status-completer-2 # An optional new status of the file request.  When the status is set to `inactive`, the file request will no longer accept new submissions, and any visitor to the file request URL will receive a `HTTP 404` status code.  This will default to the value on the existing file request. (e.g. active)
  --title: string # An optional new title for the file request. This can be used to change the title of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
]: any -> record<created_at: string, created_by: record, description: string, etag: string, expires_at: string, folder: record, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_request_id: $file_request_id} | format pattern "/file_requests/{file_request_id}"))
  let body = {"description": $description, "expires_at": $expires_at, "is_description_required": $is_description_required, "is_email_required": $is_email_required, "status": $status, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy file request
#
# POST /file_requests/{file_request_id}/copy
# operationId: post_file_requests_id_copy
# --folder shape: {id: string, type?: "folder"}
export def "file-requests-copy copy" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # An optional new description for the file request. This can be used to change the description of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
  --expires-at: string # The date after which a file request will no longer accept new submissions.  After this date, the `status` will automatically be set to `inactive`.  This will default to the value on the existing file request. (format: date-time, e.g. 2020-09-28T10:53:43-08:00)
  --is-description-required: oneof<nothing, bool> # Whether a file request submitter is required to provide a description of the files they are submitting.  When this setting is set to true, the Box UI will show a description field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --is-email-required: oneof<nothing, bool> # Whether a file request submitter is required to provide their email address.  When this setting is set to true, the Box UI will show an email field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --status: string@status-completer-2 # An optional new status of the file request.  When the status is set to `inactive`, the file request will no longer accept new submissions, and any visitor to the file request URL will receive a `HTTP 404` status code.  This will default to the value on the existing file request. (e.g. active)
  --title: string # An optional new title for the file request. This can be used to change the title of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
  folder: record # The folder to associate the new file request to. — shape: {id: string, type?: "folder"}
]: any -> record<created_at: string, created_by: record, description: string, etag: string, expires_at: string, folder: record, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_request_id: $file_request_id} | format pattern "/file_requests/{file_request_id}/copy"))
  let body = {"description": $description, "expires_at": $expires_at, "is_description_required": $is_description_required, "is_email_required": $is_email_required, "status": $status, "title": $title, "folder": $folder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List file version legal holds
#
# GET /file_version_legal_holds
# operationId: get_file_version_legal_holds
export def "file-version-legal-holds holds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string # The ID of the legal hold policy to get the file version legal holds for. (e.g. 133870)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/file_version_legal_holds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file version legal hold
#
# GET /file_version_legal_holds/{file_version_legal_hold_id}
# operationId: get_file_version_legal_holds_id
export def "file-version-legal-holds id" [
  file_version_legal_hold_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted_at: string, file: record, file_version: record, id: string, legal_hold_policy_assignments: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_version_legal_hold_id: $file_version_legal_hold_id} | format pattern "/file_version_legal_holds/{file_version_legal_hold_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List file version retentions
#
# GET /file_version_retentions
# operationId: get_file_version_retentions
export def "file-version-retentions retentions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: string # Filters results by files with this ID. (e.g. 43123123)
  --file-version-id: string # Filters results by file versions with this ID. (e.g. 1)
  --policy-id: string # Filters results by the retention policy with this ID. (e.g. 982312)
  --disposition-action: string@disposition-action-completer # Filters results by the retention policy with this disposition action. (e.g. permanently_delete)
  --disposition-before: string # Filters results by files that will have their disposition come into effect before this date. (e.g. 2012-12-12T10:53:43-08:00)
  --disposition-after: string # Filters results by files that will have their disposition come into effect after this date. (e.g. 2012-12-19T10:34:23-08:00)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_id" $file_id "scalar") (serialize-qp "file_version_id" $file_version_id "scalar") (serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "disposition_action" $disposition_action "scalar") (serialize-qp "disposition_before" $disposition_before "scalar") (serialize-qp "disposition_after" $disposition_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/file_version_retentions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get retention on file
#
# GET /file_version_retentions/{file_version_retention_id}
# operationId: get_file_version_retentions_id
export def "file-version-retentions id" [
  file_version_retention_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<applied_at: string, disposition_at: string, file: record, file_version: record, id: string, type: string, winning_retention_policy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_version_retention_id: $file_version_retention_id} | format pattern "/file_version_retentions/{file_version_retention_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preflight check before upload
#
# OPTIONS /files/content
# operationId: options_files_content
export def "files-content content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for the file (e.g. File.mp4)
  --parent: any
  --size: int # The size of the file in bytes (format: int32, e.g. 1024)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/content")
  let body = {"name": $name, "parent": $parent, "size": $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload file
#
# POST /files/content
# operationId: post_files_content
# --attributes shape: {content_created_at?: string, content_modified_at?: string, name: string, parent: record}
export def "files-content content-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --content-md5: string # An optional header containing the SHA1 hash of the file to ensure that the file was not corrupted in transit. (e.g. 134b65991ed521fcfe4724b7d814ab8ded5185dc)
  attributes: record # The additional attributes of the file being uploaded. Mainly the name and the parent folder. These attributes are part of the multi part request body and are in JSON format.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> — shape: {content_created_at?: string, content_modified_at?: string, name: string, parent: record}
  file: string # The content of the file to upload to Box.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> (format: binary)
]: any -> record<entries: list<record>, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/files/content" $qp)
  let body = {"attributes": $attributes, "file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"content-md5": $content_md5} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create upload session
#
# POST /files/upload_sessions
# operationId: post_files_upload_sessions
export def "files-upload-sessions sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file_name: string # The name of new file (e.g. Project.mov)
  file_size: int # The total number of bytes of the file to be uploaded (format: int64, e.g. 104857600)
  folder_id: string # The ID of the folder to upload the new file to. (e.g. 0)
]: any -> record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base "/files/upload_sessions")
  let body = {"file_name": $file_name, "file_size": $file_size, "folder_id": $folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove upload session
#
# DELETE /files/upload_sessions/{upload_session_id}
# operationId: delete_files_upload_sessions_id
export def "files-upload-sessions id-by-upload_session_id" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base ({upload_session_id: $upload_session_id} | format pattern "/files/upload_sessions/{upload_session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get upload session
#
# GET /files/upload_sessions/{upload_session_id}
# operationId: get_files_upload_sessions_id
export def "files-upload-sessions id-by-upload_session_id-1" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base ({upload_session_id: $upload_session_id} | format pattern "/files/upload_sessions/{upload_session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload part of file
#
# PUT /files/upload_sessions/{upload_session_id}
# operationId: put_files_upload_sessions_id
export def "files-upload-sessions id-by-upload_session_id-2" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --digest: string # The [RFC3230][1] message digest of the chunk uploaded.  Only SHA1 is supported. The SHA1 digest must be base64 encoded. The format of this header is as `sha=BASE64_ENCODED_DIGEST`.  To get the value for the `SHA` digest, use the openSSL command to encode the file part: `openssl sha1 -binary <FILE_PART_NAME> | base64`  [1]: https://tools.ietf.org/html/rfc3230 (e.g. sha=fpRyg5eVQletdZqEKaFlqwBXJzM=)
  --content-range: string # The byte range of the chunk.  Must not overlap with the range of a part already uploaded this session. Each part’s size must be exactly equal in size to the part size specified in the upload session that you created. One exception is the last part of the file, as this can be smaller.  When providing the value for `content-range`, remember that:  * The lower bound of each part's byte range   must be a multiple of the part size. * The higher bound must be a multiple of the part size - 1. (e.g. bytes 8388608-16777215/445856194)
  --body: record
]: any -> record<part: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base ({upload_session_id: $upload_session_id} | format pattern "/files/upload_sessions/{upload_session_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"digest": $digest, "content-range": $content_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Commit upload session
#
# POST /files/upload_sessions/{upload_session_id}/commit
# operationId: post_files_upload_sessions_id_commit
# --parts item shape: {offset?: int, part_id?: string, size?: int, sha1?: string}
export def "files-upload-sessions-commit commit" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --digest: string # The [RFC3230][1] message digest of the whole file.  Only SHA1 is supported. The SHA1 digest must be Base64 encoded. The format of this header is as `sha=BASE64_ENCODED_DIGEST`.  [1]: https://tools.ietf.org/html/rfc3230 (e.g. sha=fpRyg5eVQletdZqEKaFlqwBXJzM=)
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  parts: list # The list details for the uploaded parts — item shape: {offset?: int, part_id?: string, size?: int, sha1?: string}
]: any -> record<entries: list<record>, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base ({upload_session_id: $upload_session_id} | format pattern "/files/upload_sessions/{upload_session_id}/commit"))
  let body = {"parts": $parts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"digest": $digest, "if-match": $if_match, "if-none-match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List parts
#
# GET /files/upload_sessions/{upload_session_id}/parts
# operationId: get_files_upload_sessions_id_parts
export def "files-upload-sessions-parts parts" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({upload_session_id: $upload_session_id} | format pattern "/files/upload_sessions/{upload_session_id}/parts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete file
#
# DELETE /files/{file_id}
# operationId: delete_files_id
export def "files id-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}"))
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file information
#
# GET /files/{file_id}
# operationId: get_files_id
export def "files id-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested.  Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?field=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
  --x-rep-hints: string # A header required to request specific `representations` of a file. Use this in combination with the `fields` query parameter to request a specific file representation.  The general format for these representations is `X-Rep-Hints: [...]` where `[...]` is one or many hints in the format `[fileType?query]`.  For example, to request a `png` representation in `32x32` as well as `64x64` pixel dimensions provide the following hints.  `x-rep-hints: [jpg?dimensions=32x32][jpg?dimensions=64x64]`  Additionally, a `text` representation is available for all document file types in Box using the `[extracted_text]` representation.  `x-rep-hints: [extracted_text]` (e.g. [pdf])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}") $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi, "x-rep-hints": $x_rep_hints} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore file
#
# POST /files/{file_id}
# operationId: post_files_id
export def "files id-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the file. (e.g. Restored.docx)
  --parent: any
]: any -> record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, etag: string, file_version: record, id: string, item_status: string, modified_at: string, modified_by: record, name: string, owned_by: record, parent: record, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: record, sha1: string, shared_link: string, size: int, trashed_at: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}") $qp)
  let body = {"name": $name, "parent": $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update file
#
# PUT /files/{file_id}
# operationId: put_files_id
# --lock shape: {access?: "lock", expires_at?: string, is_download_prevented?: bool}
# --permissions shape: {can_download?: "open"|"company"}
export def "files id-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --description: string # The description for a file. This can be seen in the right-hand sidebar panel when viewing a file in the Box web app. Additionally, this index is used in the search index of the file, allowing users to find the file by the content in the description. (e.g. The latest reports. Automatically updated)
  --disposition-at: string # The retention expiration timestamp for the given file. This date cannot be shortened once set on a file. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --lock: record # Defines a lock on an item. This prevents the item from being moved, renamed, or otherwise changed by anyone other than the user who created the lock.  Set this to `null` to remove the lock. — shape: {access?: "lock", expires_at?: string, is_download_prevented?: bool}
  --name: string # An optional different name for the file. This can be used to rename the file. (e.g. NewFile.txt)
  --parent: any
  --permissions: record # Defines who can download a file. — shape: {can_download?: "open"|"company"}
  --shared-link: any
  --tags: list # The tags for this item. These tags are shown in the Box web app and mobile apps next to an item.  To add or remove a tag, retrieve the item's current tags, modify them, and then update this field.  There is a limit of 100 tags per item, and 10,000 unique tags per enterprise. (e.g. [approved])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}") $qp)
  let body = {"description": $description, "disposition_at": $disposition_at, "lock": $lock, "name": $name, "parent": $parent, "permissions": $permissions, "shared_link": $shared_link, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add shared link to file
#
# PUT /files/{file_id}#add_shared_link
# operationId: put_files_id#add_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
export def "files link-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the file. Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}#add_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get shared link for file
#
# GET /files/{file_id}#get_shared_link
# operationId: get_files_id#get_shared_link
export def "files link-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}#get_shared_link") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove shared link from file
#
# PUT /files/{file_id}#remove_shared_link
# operationId: put_files_id#remove_shared_link
export def "files link-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the file. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}#remove_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update shared link on file
#
# PUT /files/{file_id}#update_shared_link
# operationId: put_files_id#update_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
export def "files link-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}#update_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List file collaborations
#
# GET /files/{file_id}/collaborations
# operationId: get_files_id_collaborations
export def "files-collaborations collaborations" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/collaborations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List file comments
#
# GET /files/{file_id}/comments
# operationId: get_files_id_comments
export def "files-comments comments" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download file
#
# GET /files/{file_id}/content
# operationId: get_files_id_content
export def "files-content content-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The file version to download (e.g. 4)
  --access-token: string # An optional access token that can be used to pre-authenticate this request, which means that a download link can be shared with a browser or a third party service without them needing to know how to handle the authentication. When using this parameter, please make sure that the access token is sufficiently scoped down to only allow read access to that file and no other files or folders. (e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --range: string # The byte range of the content to download.  The format `bytes={start_byte}-{end_byte}` can be used to specify what section of the file to download. (e.g. bytes=0-1024)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/content") $qp)
  let extra_headers = {"range": $range, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload file version
#
# POST /files/{file_id}/content
# operationId: post_files_id_content
# --attributes shape: {content_modified_at?: string, name: string}
export def "files-content content-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --content-md5: string # An optional header containing the SHA1 hash of the file to ensure that the file was not corrupted in transit. (e.g. 134b65991ed521fcfe4724b7d814ab8ded5185dc)
  attributes: record # The additional attributes of the file being uploaded. Mainly the name and the parent folder. These attributes are part of the multi part request body and are in JSON format.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> — shape: {content_modified_at?: string, name: string}
  file: string # The content of the file to upload to Box.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> (format: binary)
]: any -> record<entries: list<record>, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/content") $qp)
  let body = {"attributes": $attributes, "file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match, "content-md5": $content_md5} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Copy file
#
# POST /files/{file_id}/copy
# operationId: post_files_id_copy
# --parent shape: {id: string}
export def "files-copy copy" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the copied file.  There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), and protected names like `.` and `..` are automatically sanitized by removing the non-allowed characters. (e.g. FileCopy.txt)
  parent: record # The destination folder to copy the file to. — shape: {id: string}
  --version: string # An optional ID of the specific file version to copy. (e.g. 0)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/copy") $qp)
  let body = {"name": $name, "parent": $parent, "version": $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List metadata instances on file
#
# GET /files/{file_id}/metadata
# operationId: get_files_id_metadata
export def "files-metadata metadata" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entries: list<record>, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove classification from file
#
# DELETE /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: delete_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get classification on file
#
# GET /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: get_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_canEdit: bool, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: float, _version: int, Box__Security__Classification__Key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add classification to file
#
# POST /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: post_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --box-security-classification-key: string # The name of the classification to apply to this file.  To list the available classifications in an enterprise, use the classification API to retrieve the [classification template](e://get_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema) which lists all available classification keys. (e.g. Sensitive)
]: any -> record<_canEdit: bool, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: float, _version: int, Box__Security__Classification__Key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let body = {"Box__Security__Classification__Key": $box_security_classification_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update classification on file
#
# PUT /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: put_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<_canEdit: bool, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: float, _version: int, Box__Security__Classification__Key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Remove Box Skill cards from file
#
# DELETE /files/{file_id}/metadata/global/boxSkillsCards
# operationId: delete_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/global/boxSkillsCards"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Box Skill cards on file
#
# GET /files/{file_id}/metadata/global/boxSkillsCards
# operationId: get_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_canEdit: bool, _id: string, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: int, _version: int, cards: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/global/boxSkillsCards"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Box Skill cards on file
#
# POST /files/{file_id}/metadata/global/boxSkillsCards
# operationId: post_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cards: list # A list of Box Skill cards to apply to this file.
]: any -> record<_canEdit: bool, _id: string, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: int, _version: int, cards: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/global/boxSkillsCards"))
  let body = {"cards": $cards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Box Skill cards on file
#
# PUT /files/{file_id}/metadata/global/boxSkillsCards
# operationId: put_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<_canEdit: bool, _id: string, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: int, _version: int, cards: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/metadata/global/boxSkillsCards"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Remove metadata instance from file
#
# DELETE /files/{file_id}/metadata/{scope}/{template_key}
# operationId: delete_files_id_metadata_id_id
export def "files-metadata id-by-file_id-scope-template_key" [
  file_id: string
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id, scope: $scope, template_key: $template_key} | format pattern "/files/{file_id}/metadata/{scope}/{template_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata instance on file
#
# GET /files/{file_id}/metadata/{scope}/{template_key}
# operationId: get_files_id_metadata_id_id
export def "files-metadata id-by-file_id-scope-template_key-1" [
  file_id: string
  scope: string
  template_key: string
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
  let full_url = (build-url $base ({file_id: $file_id, scope: $scope, template_key: $template_key} | format pattern "/files/{file_id}/metadata/{scope}/{template_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create metadata instance on file
#
# POST /files/{file_id}/metadata/{scope}/{template_key}
# operationId: post_files_id_metadata_id_id
export def "files-metadata id-by-file_id-scope-template_key-2" [
  file_id: string
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id, scope: $scope, template_key: $template_key} | format pattern "/files/{file_id}/metadata/{scope}/{template_key}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update metadata instance on file
#
# PUT /files/{file_id}/metadata/{scope}/{template_key}
# operationId: put_files_id_metadata_id_id
export def "files-metadata id-by-file_id-scope-template_key-3" [
  file_id: string
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id, scope: $scope, template_key: $template_key} | format pattern "/files/{file_id}/metadata/{scope}/{template_key}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# List tasks on file
#
# GET /files/{file_id}/tasks
# operationId: get_files_id_tasks
export def "files-tasks tasks" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entries: table<action: string, completion_rule: string, created_at: string, created_by: record, due_at: string, id: string, is_completed: bool, item: record, message: string, task_assignment_collection: record, type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/tasks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file thumbnail
#
# GET /files/{file_id}/thumbnail.{extension}
# operationId: get_files_id_thumbnail_id
export def "files-thumbnail-extension id" [
  file_id: string
  extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --min-height: int # The minimum height of the thumbnail (e.g. 32)
  --min-width: int # The minimum width of the thumbnail (e.g. 32)
  --max-height: int # The maximum height of the thumbnail (e.g. 320)
  --max-width: int # The maximum width of the thumbnail (e.g. 320)
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_height" $min_height "scalar") (serialize-qp "min_width" $min_width "scalar") (serialize-qp "max_height" $max_height "scalar") (serialize-qp "max_width" $max_width "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id, extension: $extension} | format pattern "/files/{file_id}/thumbnail.{extension}") $qp)
  let accept_val = ($accept | default "image/jpg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently remove file
#
# DELETE /files/{file_id}/trash
# operationId: delete_files_id_trash
export def "files-trash trash-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/trash"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trashed file
#
# GET /files/{file_id}/trash
# operationId: get_files_id_trash
export def "files-trash trash-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, etag: string, file_version: record, id: string, item_status: string, modified_at: string, modified_by: record, name: string, owned_by: record, parent: record, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: record, sha1: string, shared_link: string, size: int, trashed_at: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/trash") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create upload session for existing file
#
# POST /files/{file_id}/upload_sessions
# operationId: post_files_id_upload_sessions
export def "files-upload-sessions sessions-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-name: string # The optional new name of new file (e.g. Project.mov)
  file_size: int # The total number of bytes of the file to be uploaded (format: int64, e.g. 104857600)
]: any -> record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/upload_sessions"))
  let body = {"file_name": $file_name, "file_size": $file_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all file versions
#
# GET /files/{file_id}/versions
# operationId: get_files_id_versions
export def "files-versions version-s" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promote file version
#
# POST /files/{file_id}/versions/current
# operationId: post_files_id_versions_current
export def "files-versions-current current" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --id: string # The file version ID (e.g. 11446498)
  --type: string@type-completer # The type to promote (e.g. file_version)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/versions/current") $qp)
  let body = {"id": $id, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove file version
#
# DELETE /files/{file_id}/versions/{file_version_id}
# operationId: delete_files_id_versions_id
export def "files-versions id-by-file_id-file_version_id" [
  file_id: string
  file_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id, file_version_id: $file_version_id} | format pattern "/files/{file_id}/versions/{file_version_id}"))
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file version
#
# GET /files/{file_id}/versions/{file_version_id}
# operationId: get_files_id_versions_id
export def "files-versions id-by-file_id-file_version_id-1" [
  file_id: string
  file_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id, file_version_id: $file_version_id} | format pattern "/files/{file_id}/versions/{file_version_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore file version
#
# PUT /files/{file_id}/versions/{file_version_id}
# operationId: put_files_id_versions_id
export def "files-versions id-by-file_id-file_version_id-2" [
  file_id: string
  file_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trashed-at: string # Set this to `null` to clear the date and restore the file. (e.g. null)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id, file_version_id: $file_version_id} | format pattern "/files/{file_id}/versions/{file_version_id}"))
  let body = {"trashed_at": $trashed_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove watermark from file
#
# DELETE /files/{file_id}/watermark
# operationId: delete_files_id_watermark
export def "files-watermark watermark-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/watermark"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watermark on file
#
# GET /files/{file_id}/watermark
# operationId: get_files_id_watermark
export def "files-watermark watermark-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<watermark: record<created_at: string, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/watermark"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apply watermark to file
#
# PUT /files/{file_id}/watermark
# operationId: put_files_id_watermark
# --watermark shape: {imprint: "default"}
export def "files-watermark watermark-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  watermark: record # The watermark to imprint on the file — shape: {imprint: "default"}
]: any -> record<watermark: record<created_at: string, modified_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/{file_id}/watermark"))
  let body = {"watermark": $watermark} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List folder locks
#
# GET /folder_locks
# operationId: get_folder_locks
export def "folder-locks lock-s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --folder-id: string # The unique identifier that represent a folder.  The ID for any folder can be determined by visiting this folder in the web application and copying the ID from the URL. For example, for the URL `https://*.app.box.com/folder/123` the `folder_id` is `123`.  The root folder of a Box account is always represented by the ID `0`. (e.g. 12345)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folder_id" $folder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folder_locks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create folder lock
#
# POST /folder_locks
# operationId: post_folder_locks
# --folder shape: {id: string, type: string}
# --locked_operations shape: {delete: bool, move: bool}
export def "folder-locks lock-s-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  folder: record # The folder to apply the lock to. — shape: {id: string, type: string}
  --locked-operations: record # The operations to lock for the folder. If `locked_operations` is included in the request, both `move` and `delete` must also be included and both set to `true`. — shape: {delete: bool, move: bool}
]: any -> record<created_at: string, created_by: record<id: string, type: string>, folder: record, id: string, lock_type: string, locked_operations: record<delete: bool, move: bool>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/folder_locks")
  let body = {"folder": $folder, "locked_operations": $locked_operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete folder lock
#
# DELETE /folder_locks/{folder_lock_id}
# operationId: delete_folder_locks_id
export def "folder-locks id" [
  folder_lock_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_lock_id: $folder_lock_id} | format pattern "/folder_locks/{folder_lock_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create folder
#
# POST /folders
# operationId: post_folders
# --parent shape: {id: string}
export def "folders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --folder-upload-email: any
  name: string # The name for the new folder.  There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), as well as names with trailing spaces are prohibited.  Additionally, the names `.` and `..` are not allowed either. (e.g. New Folder)
  parent: record # The parent folder to create the new folder within. — shape: {id: string}
  --sync-state: string@sync-state-completer # Specifies whether a folder should be synced to a user's device or not. This is used by Box Sync (discontinued) and is not used by Box Drive. (e.g. synced)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/folders" $qp)
  let body = {"folder_upload_email": $folder_upload_email, "name": $name, "parent": $parent, "sync_state": $sync_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List trashed items
#
# GET /folders/trash/items
# operationId: get_folders_trash_items
export def "folders-trash-items items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --usemarker: oneof<nothing, bool> # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time.  By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --direction: string@direction-completer-1 # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
  --qp-sort: string@sort-completer # Defines the **second** attribute by which items are sorted.  Items are always sorted by their `type` first, with folders listed before files, and files listed before web links.  This parameter is not supported when using marker-based pagination. (e.g. id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "usemarker" $usemarker "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folders/trash/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete folder
#
# DELETE /folders/{folder_id}
# operationId: delete_folders_id
export def "folders id-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # Delete a folder that is not empty by recursively deleting the folder and all of its content. (e.g. true)
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recursive" $recursive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}") $qp)
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get folder information
#
# GET /folders/{folder_id}
# operationId: get_folders_id
export def "folders id-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested.  Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?field=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}") $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore folder
#
# POST /folders/{folder_id}
# operationId: post_folders_id
export def "folders id-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the folder. (e.g. Restored Photos)
  --parent: any
]: any -> record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: record, etag: string, folder_upload_email: string, id: string, item_status: string, modified_at: string, modified_by: record, name: string, owned_by: record, parent: record, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: record, shared_link: string, size: int, trashed_at: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}") $qp)
  let body = {"name": $name, "parent": $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update folder
#
# PUT /folders/{folder_id}
# operationId: put_folders_id
# --collections item shape: {id?: string, type?: string}
# --parent shape: {id?: string}
export def "folders id-by-folder_id-3" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --can-non-owners-invite: oneof<nothing, bool> # Specifies if users who are not the owner of the folder can invite new collaborators to the folder. (e.g. true)
  --can-non-owners-view-collaborators: oneof<nothing, bool> # Restricts collaborators who are not the owner of this folder from viewing other collaborations on this folder.  It also restricts non-owners from inviting new collaborators.  When setting this field to `false`, it is required to also set `can_non_owners_invite_collaborators` to `false` if it has not already been set. (e.g. true)
  --collections: list # An array of collections to make this folder a member of. Currently we only support the `favorites` collection.  To get the ID for a collection, use the [List all collections][1] endpoint.  Passing an empty array `[]` or `null` will remove the folder from all collections.  [1]: ../advanced-files-and-folders/#get-collections — item shape: {id?: string, type?: string}
  --description: string # The optional description of this folder (e.g. Legal contracts for the new ACME deal)
  --folder-upload-email: any
  --is-collaboration-restricted-to-enterprise: oneof<nothing, bool> # Specifies if new invites to this folder are restricted to users within the enterprise. This does not affect existing collaborations. (e.g. true)
  --name: string # The optional new name for this folder. (e.g. New Folder)
  --parent: record # The parent folder for this folder. Use this to move the folder or to restore it out of the trash. — shape: {id?: string}
  --shared-link: any
  --sync-state: string@sync-state-completer # Specifies whether a folder should be synced to a user's device or not. This is used by Box Sync (discontinued) and is not used by Box Drive. (e.g. synced)
  --tags: list # The tags for this item. These tags are shown in the Box web app and mobile apps next to an item.  To add or remove a tag, retrieve the item's current tags, modify them, and then update this field.  There is a limit of 100 tags per item, and 10,000 unique tags per enterprise. (e.g. [approved])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}") $qp)
  let body = {"can_non_owners_invite": $can_non_owners_invite, "can_non_owners_view_collaborators": $can_non_owners_view_collaborators, "collections": $collections, "description": $description, "folder_upload_email": $folder_upload_email, "is_collaboration_restricted_to_enterprise": $is_collaboration_restricted_to_enterprise, "name": $name, "parent": $parent, "shared_link": $shared_link, "sync_state": $sync_state, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add shared link to folder
#
# PUT /folders/{folder_id}#add_shared_link
# operationId: put_folders_id#add_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
export def "folders link-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the folder.  Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}#add_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get shared link for folder
#
# GET /folders/{folder_id}#get_shared_link
# operationId: get_folders_id#get_shared_link
export def "folders link-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}#get_shared_link") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove shared link from folder
#
# PUT /folders/{folder_id}#remove_shared_link
# operationId: put_folders_id#remove_shared_link
export def "folders link-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the folder. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}#remove_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update shared link on folder
#
# PUT /folders/{folder_id}#update_shared_link
# operationId: put_folders_id#update_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
export def "folders link-by-folder_id-3" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}#update_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List folder collaborations
#
# GET /folders/{folder_id}/collaborations
# operationId: get_folders_id_collaborations
export def "folders-collaborations collaborations" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/collaborations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Copy folder
#
# POST /folders/{folder_id}/copy
# operationId: post_folders_id_copy
# --parent shape: {id: string}
export def "folders-copy copy" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the copied folder.  There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), as well as names with trailing spaces are prohibited.  Additionally, the names `.` and `..` are not allowed either. (e.g. New Folder)
  parent: record # The destination folder to copy the folder to. — shape: {id: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/copy") $qp)
  let body = {"name": $name, "parent": $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List items in folder
#
# GET /folders/{folder_id}/items
# operationId: get_folders_id_items
export def "folders-items items" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested.  Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?field=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --usemarker: oneof<nothing, bool> # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time.  By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --qp-sort: string@sort-completer # Defines the **second** attribute by which items are sorted.  Items are always sorted by their `type` first, with folders listed before files, and files listed before web links.  This parameter is not supported for marker-based pagination on the root folder (the folder with an ID of `0`). (e.g. id)
  --direction: string@direction-completer-1 # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "usemarker" $usemarker "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/items") $qp)
  let extra_headers = {"boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List metadata instances on folder
#
# GET /folders/{folder_id}/metadata
# operationId: get_folders_id_metadata
export def "folders-metadata metadata" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entries: list<record>, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove classification from folder
#
# DELETE /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: delete_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get classification on folder
#
# GET /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: get_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_canEdit: bool, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: float, _version: int, Box__Security__Classification__Key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add classification to folder
#
# POST /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: post_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --box-security-classification-key: string # The name of the classification to apply to this folder.  To list the available classifications in an enterprise, use the classification API to retrieve the [classification template](e://get_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema) which lists all available classification keys. (e.g. Sensitive)
]: any -> record<_canEdit: bool, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: float, _version: int, Box__Security__Classification__Key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let body = {"Box__Security__Classification__Key": $box_security_classification_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update classification on folder
#
# PUT /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: put_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id-3" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<_canEdit: bool, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: float, _version: int, Box__Security__Classification__Key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Remove metadata instance from folder
#
# DELETE /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: delete_folders_id_metadata_id_id
export def "folders-metadata id-by-folder_id-scope-template_key" [
  folder_id: string
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id, scope: $scope, template_key: $template_key} | format pattern "/folders/{folder_id}/metadata/{scope}/{template_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata instance on folder
#
# GET /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: get_folders_id_metadata_id_id
export def "folders-metadata id-by-folder_id-scope-template_key-1" [
  folder_id: string
  scope: string
  template_key: string
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
  let full_url = (build-url $base ({folder_id: $folder_id, scope: $scope, template_key: $template_key} | format pattern "/folders/{folder_id}/metadata/{scope}/{template_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create metadata instance on folder
#
# POST /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: post_folders_id_metadata_id_id
export def "folders-metadata id-by-folder_id-scope-template_key-2" [
  folder_id: string
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id, scope: $scope, template_key: $template_key} | format pattern "/folders/{folder_id}/metadata/{scope}/{template_key}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update metadata instance on folder
#
# PUT /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: put_folders_id_metadata_id_id
export def "folders-metadata id-by-folder_id-scope-template_key-3" [
  folder_id: string
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id, scope: $scope, template_key: $template_key} | format pattern "/folders/{folder_id}/metadata/{scope}/{template_key}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Permanently remove folder
#
# DELETE /folders/{folder_id}/trash
# operationId: delete_folders_id_trash
export def "folders-trash trash-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/trash"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trashed folder
#
# GET /folders/{folder_id}/trash
# operationId: get_folders_id_trash
export def "folders-trash trash-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: record, etag: string, folder_upload_email: string, id: string, item_status: string, modified_at: string, modified_by: record, name: string, owned_by: record, parent: record, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: record, shared_link: string, size: int, trashed_at: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/trash") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove watermark from folder
#
# DELETE /folders/{folder_id}/watermark
# operationId: delete_folders_id_watermark
export def "folders-watermark watermark-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/watermark"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watermark for folder
#
# GET /folders/{folder_id}/watermark
# operationId: get_folders_id_watermark
export def "folders-watermark watermark-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<watermark: record<created_at: string, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/watermark"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apply watermark to folder
#
# PUT /folders/{folder_id}/watermark
# operationId: put_folders_id_watermark
# --watermark shape: {imprint: "default"}
export def "folders-watermark watermark-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  watermark: record # The watermark to imprint on the folder — shape: {imprint: "default"}
]: any -> record<watermark: record<created_at: string, modified_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/folders/{folder_id}/watermark"))
  let body = {"watermark": $watermark} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add user to group
#
# POST /group_memberships
# operationId: post_group_memberships
# --group shape: {id: string}
# --user shape: {id: string}
export def "group-memberships memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --configurable-permissions: record # Custom configuration for the permissions an admin if a group will receive. This option has no effect on members with a role of `member`.  Setting these permissions overwrites the default access levels of an admin.  Specifying a value of "null" for this object will disable all configurable permissions. Specifying permissions will set them accordingly, omitted permissions will be enabled by default. (e.g. {can_run_reports: true})
  group: record # The group to add the user to. — shape: {id: string}
  --role: string@role-completer-2 # The role of the user in the group. (e.g. member)
  user: record # The user to add to the group. — shape: {id: string}
]: any -> record<created_at: string, group: record, id: string, modified_at: string, role: string, type: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/group_memberships" $qp)
  let body = {"configurable_permissions": $configurable_permissions, "group": $group, "role": $role, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove user from group
#
# DELETE /group_memberships/{group_membership_id}
# operationId: delete_group_memberships_id
export def "group-memberships id-by-group_membership_id" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_membership_id: $group_membership_id} | format pattern "/group_memberships/{group_membership_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group membership
#
# GET /group_memberships/{group_membership_id}
# operationId: get_group_memberships_id
export def "group-memberships id-by-group_membership_id-1" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<created_at: string, group: record, id: string, modified_at: string, role: string, type: string, user: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({group_membership_id: $group_membership_id} | format pattern "/group_memberships/{group_membership_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group membership
#
# PUT /group_memberships/{group_membership_id}
# operationId: put_group_memberships_id
export def "group-memberships id-by-group_membership_id-2" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --configurable-permissions: record # Custom configuration for the permissions an admin if a group will receive. This option has no effect on members with a role of `member`.  Setting these permissions overwrites the default access levels of an admin.  Specifying a value of "null" for this object will disable all configurable permissions. Specifying permissions will set them accordingly, omitted permissions will be enabled by default. (e.g. {can_run_reports: true})
  --role: string@role-completer-2 # The role of the user in the group. (e.g. member)
]: any -> record<created_at: string, group: record, id: string, modified_at: string, role: string, type: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({group_membership_id: $group_membership_id} | format pattern "/group_memberships/{group_membership_id}") $qp)
  let body = {"configurable_permissions": $configurable_permissions, "role": $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List groups for enterprise
#
# GET /groups
# operationId: get_groups
export def "groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-term: string # Limits the results to only groups whose `name` starts with the search term. (e.g. Engineering)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_term" $filter_term "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create group
#
# POST /groups
# operationId: post_groups
export def "groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --description: string # A human readable description of the group. (e.g. "Customer Support Group - as imported from Active Directory")
  --external-sync-identifier: string # An arbitrary identifier that can be used by external group sync tools to link this Box Group to an external group.  Example values of this field could be an **Active Directory Object ID** or a **Google Group ID**.  We recommend you use of this field in order to avoid issues when group names are updated in either Box or external systems. (e.g. AD:123456)
  --invitability-level: string@invitability-level-completer # Specifies who can invite the group to collaborate on folders.  When set to `admins_only` the enterprise admin, co-admins, and the group's admin can invite the group.  When set to `admins_and_members` all the admins listed above and group members can invite the group.  When set to `all_managed_users` all managed users in the enterprise can invite the group. (e.g. admins_only)
  --member-viewability-level: string@member-viewability-level-completer # Specifies who can see the members of the group.  * `admins_only` - the enterprise admin, co-admins, group's   group admin * `admins_and_members` - all admins and group members * `all_managed_users` - all managed users in the   enterprise (e.g. admins_only)
  name: string # The name of the new group to be created. This name must be unique within the enterprise. (e.g. Customer Support)
  --provenance: string # Keeps track of which external source this group is coming, for example `Active Directory`, or `Okta`.  Setting this will also prevent Box admins from editing the group name and its members directly via the Box web application.  This is desirable for one-way syncing of groups. (e.g. Active Directory)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let body = {"description": $description, "external_sync_identifier": $external_sync_identifier, "invitability_level": $invitability_level, "member_viewability_level": $member_viewability_level, "name": $name, "provenance": $provenance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create jobs to terminate user group session
#
# POST /groups/terminate_sessions
# operationId: post_groups_terminate_sessions
export def "groups-terminate-sessions sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group_ids: list # A list of group IDs (e.g. [123456, 456789])
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/terminate_sessions")
  let body = {"group_ids": $group_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove group
#
# DELETE /groups/{group_id}
# operationId: delete_groups_id
export def "groups id-by-group_id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group
#
# GET /groups/{group_id}
# operationId: get_groups_id
export def "groups id-by-group_id-1" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/groups/{group_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group
#
# PUT /groups/{group_id}
# operationId: put_groups_id
export def "groups id-by-group_id-2" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --description: string # A human readable description of the group. (e.g. "Customer Support Group - as imported from Active Directory")
  --external-sync-identifier: string # An arbitrary identifier that can be used by external group sync tools to link this Box Group to an external group.  Example values of this field could be an **Active Directory Object ID** or a **Google Group ID**.  We recommend you use of this field in order to avoid issues when group names are updated in either Box or external systems. (e.g. AD:123456)
  --invitability-level: string@invitability-level-completer # Specifies who can invite the group to collaborate on folders.  When set to `admins_only` the enterprise admin, co-admins, and the group's admin can invite the group.  When set to `admins_and_members` all the admins listed above and group members can invite the group.  When set to `all_managed_users` all managed users in the enterprise can invite the group. (e.g. admins_only)
  --member-viewability-level: string@member-viewability-level-completer # Specifies who can see the members of the group.  * `admins_only` - the enterprise admin, co-admins, group's   group admin * `admins_and_members` - all admins and group members * `all_managed_users` - all managed users in the   enterprise (e.g. admins_only)
  --name: string # The name of the new group to be created. Must be unique within the enterprise. (e.g. Customer Support)
  --provenance: string # Keeps track of which external source this group is coming, for example `Active Directory`, or `Okta`.  Setting this will also prevent Box admins from editing the group name and its members directly via the Box web application.  This is desirable for one-way syncing of groups. (e.g. Active Directory)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/groups/{group_id}") $qp)
  let body = {"description": $description, "external_sync_identifier": $external_sync_identifier, "invitability_level": $invitability_level, "member_viewability_level": $member_viewability_level, "name": $name, "provenance": $provenance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List group collaborations
#
# GET /groups/{group_id}/collaborations
# operationId: get_groups_id_collaborations
export def "groups-collaborations collaborations" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/groups/{group_id}/collaborations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List members of group
#
# GET /groups/{group_id}/memberships
# operationId: get_groups_id_memberships
export def "groups-memberships memberships" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/groups/{group_id}/memberships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create user invite
#
# POST /invites
# operationId: post_invites
# --actionable_by shape: {login?: string}
# --enterprise shape: {id: string}
export def "invites post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  actionable_by: record # The user to invite — shape: {login?: string}
  enterprise: record # The enterprise to invite the user to — shape: {id: string}
]: any -> record<actionable_by: record, created_at: string, id: string, invited_by: record, invited_to: record<id: string, name: string, type: string>, modified_at: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/invites" $qp)
  let body = {"actionable_by": $actionable_by, "enterprise": $enterprise} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get user invite status
#
# GET /invites/{invite_id}
# operationId: get_invites_id
export def "invites id" [
  invite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<actionable_by: record, created_at: string, id: string, invited_by: record, invited_to: record<id: string, name: string, type: string>, modified_at: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({invite_id: $invite_id} | format pattern "/invites/{invite_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all legal hold policies
#
# GET /legal_hold_policies
# operationId: get_legal_hold_policies
export def "legal-hold-policies policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-name: string # Limits results to policies for which the names start with this search term. This is a case-insensitive prefix. (e.g. Sales Policy)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_name" $policy_name "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/legal_hold_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create legal hold policy
#
# POST /legal_hold_policies
# operationId: post_legal_hold_policies
export def "legal-hold-policies policies-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the policy. (e.g. A custom policy for the sales team)
  --filter-ended-at: string # The filter end date.  When this policy is applied using a `custodian` legal hold assignments, it will only apply to file versions created or uploaded inside of the date range. Other assignment types, such as folders and files, will ignore the date filter.  Required if `is_ongoing` is set to `false`. (format: date-time, e.g. 2012-12-18T10:53:43-08:00)
  --filter-started-at: string # The filter start date.  When this policy is applied using a `custodian` legal hold assignments, it will only apply to file versions created or uploaded inside of the date range. Other assignment types, such as folders and files, will ignore the date filter.  Required if `is_ongoing` is set to `false`. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --is-ongoing: oneof<nothing, bool> # Whether new assignments under this policy should continue applying to files even after initialization.  When this policy is applied using a legal hold assignment, it will continue applying the policy to any new file versions even after it has been applied.  For example, if a legal hold assignment is placed on a user today, and that user uploads a file tomorrow, that file will get held. This will continue until the policy is retired.  Required if no filter dates are set. (e.g. true)
  policy_name: string # The name of the policy. (e.g. Sales Policy)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legal_hold_policies")
  let body = {"description": $description, "filter_ended_at": $filter_ended_at, "filter_started_at": $filter_started_at, "is_ongoing": $is_ongoing, "policy_name": $policy_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove legal hold policy
#
# DELETE /legal_hold_policies/{legal_hold_policy_id}
# operationId: delete_legal_hold_policies_id
export def "legal-hold-policies id-by-legal_hold_policy_id" [
  legal_hold_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({legal_hold_policy_id: $legal_hold_policy_id} | format pattern "/legal_hold_policies/{legal_hold_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get legal hold policy
#
# GET /legal_hold_policies/{legal_hold_policy_id}
# operationId: get_legal_hold_policies_id
export def "legal-hold-policies id-by-legal_hold_policy_id-1" [
  legal_hold_policy_id: string
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
  let full_url = (build-url $base ({legal_hold_policy_id: $legal_hold_policy_id} | format pattern "/legal_hold_policies/{legal_hold_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update legal hold policy
#
# PUT /legal_hold_policies/{legal_hold_policy_id}
# operationId: put_legal_hold_policies_id
export def "legal-hold-policies id-by-legal_hold_policy_id-2" [
  legal_hold_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the policy. (e.g. A custom policy for the sales team)
  --policy-name: string # The name of the policy. (e.g. Sales Policy)
  --release-notes: string # Notes around why the policy was released. (e.g. Required for GDPR)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({legal_hold_policy_id: $legal_hold_policy_id} | format pattern "/legal_hold_policies/{legal_hold_policy_id}"))
  let body = {"description": $description, "policy_name": $policy_name, "release_notes": $release_notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List legal hold policy assignments
#
# GET /legal_hold_policy_assignments
# operationId: get_legal_hold_policy_assignments
export def "legal-hold-policy-assignments assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string # The ID of the legal hold policy (e.g. 324432)
  --assign-to-type: string@assign-to-type-completer # Filters the results by the type of item the policy was applied to. (e.g. file)
  --assign-to-id: string # Filters the results by the ID of item the policy was applied to. (e.g. 1234323)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "assign_to_type" $assign_to_type "scalar") (serialize-qp "assign_to_id" $assign_to_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/legal_hold_policy_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign legal hold policy
#
# POST /legal_hold_policy_assignments
# operationId: post_legal_hold_policy_assignments
# --assign_to shape: {id: string, type: "file"|"file_version"|"folder"|"user"}
export def "legal-hold-policy-assignments assignments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assign_to: record # The item to assign the policy to — shape: {id: string, type: "file"|"file_version"|"folder"|"user"}
  policy_id: string # The ID of the policy to assign. (e.g. 123244)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legal_hold_policy_assignments")
  let body = {"assign_to": $assign_to, "policy_id": $policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unassign legal hold policy
#
# DELETE /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}
# operationId: delete_legal_hold_policy_assignments_id
export def "legal-hold-policy-assignments id-by-legal_hold_policy_assignment_id" [
  legal_hold_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id} | format pattern "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get legal hold policy assignment
#
# GET /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}
# operationId: get_legal_hold_policy_assignments_id
export def "legal-hold-policy-assignments id-by-legal_hold_policy_assignment_id-1" [
  legal_hold_policy_assignment_id: string
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
  let full_url = (build-url $base ({legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id} | format pattern "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List previous file versions for legal hold policy assignment
#
# GET /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/file_versions_on_hold
# operationId: get_legal_hold_policy_assignments_id_file_versions_on_hold
export def "legal-hold-policy-assignments-file-versions-on-hold hold" [
  legal_hold_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id} | format pattern "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/file_versions_on_hold") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List current file versions for legal hold policy assignment
#
# GET /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/files_on_hold
# operationId: get_legal_hold_policy_assignments_id_files_on_hold
export def "legal-hold-policy-assignments-files-on-hold hold" [
  legal_hold_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id} | format pattern "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/files_on_hold") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List metadata cascade policies
#
# GET /metadata_cascade_policies
# operationId: get_metadata_cascade_policies
export def "metadata-cascade-policies policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --folder-id: string # Specifies which folder to return policies for. This can not be used on the root folder with ID `0`. (e.g. 31232)
  --owner-enterprise-id: string # The ID of the enterprise ID for which to find metadata cascade policies. If not specified, it defaults to the current enterprise. (e.g. 31232)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folder_id" $folder_id "scalar") (serialize-qp "owner_enterprise_id" $owner_enterprise_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_cascade_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create metadata cascade policy
#
# POST /metadata_cascade_policies
# operationId: post_metadata_cascade_policies
export def "metadata-cascade-policies policies-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  folder_id: string # The ID of the folder to apply the policy to. This folder will need to already have an instance of the targeted metadata template applied to it. (e.g. 1234567)
  scope: string@scope-completer # The scope of the targeted metadata template. This template will need to already have an instance applied to the targeted folder. (e.g. enterprise)
  template_key: string # The key of the targeted metadata template. This template will need to already have an instance applied to the targeted folder.  In many cases the template key is automatically derived of its display name, for example `Contract Template` would become `contractTemplate`. In some cases the creator of the template will have provided its own template key.  Please [list the templates for an enterprise][list], or get all instances on a [file][file] or [folder][folder] to inspect a template's key.  [list]: e://get-metadata-templates-enterprise [file]: e://get-files-id-metadata [folder]: e://get-folders-id-metadata (e.g. productInfo)
]: any -> record<id: string, owner_enterprise: record<id: string, type: string>, parent: record<id: string, type: string>, scope: string, templateKey: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_cascade_policies")
  let body = {"folder_id": $folder_id, "scope": $scope, "templateKey": $template_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove metadata cascade policy
#
# DELETE /metadata_cascade_policies/{metadata_cascade_policy_id}
# operationId: delete_metadata_cascade_policies_id
export def "metadata-cascade-policies id-by-metadata_cascade_policy_id" [
  metadata_cascade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({metadata_cascade_policy_id: $metadata_cascade_policy_id} | format pattern "/metadata_cascade_policies/{metadata_cascade_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata cascade policy
#
# GET /metadata_cascade_policies/{metadata_cascade_policy_id}
# operationId: get_metadata_cascade_policies_id
export def "metadata-cascade-policies id-by-metadata_cascade_policy_id-1" [
  metadata_cascade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, owner_enterprise: record<id: string, type: string>, parent: record<id: string, type: string>, scope: string, templateKey: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({metadata_cascade_policy_id: $metadata_cascade_policy_id} | format pattern "/metadata_cascade_policies/{metadata_cascade_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force-apply metadata cascade policy to folder
#
# POST /metadata_cascade_policies/{metadata_cascade_policy_id}/apply
# operationId: post_metadata_cascade_policies_id_apply
export def "metadata-cascade-policies-apply apply" [
  metadata_cascade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  conflict_resolution: string@conflict-resolution-completer # Describes the desired behavior when dealing with the conflict where a metadata template already has an instance applied to a child.  * `none` will preserve the existing value on the file * `overwrite` will force-apply the templates values over   any existing values. (e.g. none)
]: any -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({metadata_cascade_policy_id: $metadata_cascade_policy_id} | format pattern "/metadata_cascade_policies/{metadata_cascade_policy_id}/apply"))
  let body = {"conflict_resolution": $conflict_resolution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query files/folders by metadata
#
# POST /metadata_queries/execute_read
# operationId: post_metadata_queries_execute_read
# --order_by item shape: {direction?: "ASC"|"DESC"|"asc"|"desc", field_key?: string}
export def "metadata-queries-execute-read read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ancestor_folder_id: string # The ID of the folder that you are restricting the query to. A value of zero will return results from all folders you have access to. A non-zero value will only return results found in the folder corresponding to the ID or in any of its subfolders. (e.g. 0)
  --fields: list # By default, this endpoint returns only the most basic info about the items for which the query matches. This attribute can be used to specify a list of additional attributes to return for any item, including its metadata.  This attribute takes a list of item fields, metadata template identifiers, or metadata template field identifiers.  For example:  * `created_by` will add the details of the user who created the item to the response. * `metadata.<scope>.<templateKey>` will return the mini-representation of the metadata instance identified by the `scope` and `templateKey`. * `metadata.<scope>.<templateKey>.<field>` will return all the mini-representation of the metadata instance identified by the `scope` and `templateKey` plus the field specified by the `field` name. Multiple fields for the same `scope` and `templateKey` can be defined. (e.g. [extension, created_at, item_status, metadata.enterprise_1234.contracts, metadata.enterprise_1234.regions.location])
  --body-from: string # Specifies the template used in the query. Must be in the form `scope.templateKey`. Not all templates can be used in this field, most notably the built-in, Box-provided classification templates can not be used in a query. (e.g. enterprise_123456.someTemplate)
  --limit: int # A value between 0 and 100 that indicates the maximum number of results to return for a single request. This only specifies a maximum boundary and will not guarantee the minimum number of results returned. (default: 100, e.g. 50)
  --marker: string # Marker to use for requesting the next page. (e.g. AAAAAmVYB1FWec8GH6yWu2nwmanfMh07IyYInaa7DZDYjgO1H4KoLW29vPlLY173OKsci6h6xGh61gG73gnaxoS+o0BbI1/h6le6cikjlupVhASwJ2Cj0tOD9wlnrUMHHw3/ISf+uuACzrOMhN6d5fYrbidPzS6MdhJOejuYlvsg4tcBYzjauP3+VU51p77HFAIuObnJT0ff)
  --order-by: list # A list of template fields and directions to sort the metadata query results by.  The ordering `direction` must be the same for each item in the array. — item shape: {direction?: "ASC"|"DESC"|"asc"|"desc", field_key?: string}
  --query: string # The query to perform. A query is a logical expression that is very similar to a SQL `SELECT` statement. Values in the search query can be turned into parameters specified in the `query_param` arguments list to prevent having to manually insert search values into the query string.  For example, a value of `:amount` would represent the `amount` value in `query_params` object. (e.g. value >= :amount)
  --query-params: record # Set of arguments corresponding to the parameters specified in the `query`. The type of each parameter used in the `query_params` must match the type of the corresponding metadata template field. (e.g. {amount: 100})
]: any -> record<entries: list<any>, limit: int, next_marker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_queries/execute_read")
  let body = {"ancestor_folder_id": $ancestor_folder_id, "fields": $fields, "from": $body_from, "limit": $limit, "marker": $marker, "order_by": $order_by, "query": $query, "query_params": $query_params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List metadata query indices
#
# GET /metadata_query_indices
# operationId: get_metadata_query_indices
export def "metadata-query-indices indices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # The scope of the metadata template (e.g. global)
  --template-key: string # The name of the metadata template (e.g. properties)
]: nothing -> record<entries: table<fields: list, id: string, status: string, type: string>, limit: int, next_marker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "template_key" $template_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_query_indices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find metadata template by instance ID
#
# GET /metadata_templates
# operationId: get_metadata_templates
export def "metadata-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-instance-id: string # The ID of an instance of the metadata template to find. (format: uuid, e.g. 01234500-12f1-1234-aa12-b1d234cb567e)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata_instance_id" $metadata_instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all metadata templates for enterprise
#
# GET /metadata_templates/enterprise
# operationId: get_metadata_templates_enterprise
export def "metadata-templates-enterprise enterprise" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_templates/enterprise" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all classifications
#
# DELETE /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# operationId: delete_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema
export def "metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all classifications
#
# GET /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# operationId: get_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema
export def "metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema schema-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add classification
#
# PUT /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#add
# operationId: put_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema#add
export def "metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaadd schemaadd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#add")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Delete classification
#
# PUT /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#delete
# operationId: put_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema#delete
export def "metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemadelete schemadelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#delete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Update classification
#
# PUT /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#update
# operationId: put_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema#update
export def "metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaupdate schemaupdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#update")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# List all global metadata templates
#
# GET /metadata_templates/global
# operationId: get_metadata_templates_global
export def "metadata-templates-global global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_templates/global" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create metadata template
#
# POST /metadata_templates/schema
# operationId: post_metadata_templates_schema
# --fields item shape: {description?: string, displayName: string, hidden?: bool, key: string, options?: list, type: "string"|"float"|"date"|"enum"|"multiSelect"}
export def "metadata-templates-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --copy-instance-on-item-copy: oneof<nothing, bool> # Whether or not to copy any metadata attached to a file or folder when it is copied. By default, metadata is not copied along with a file or folder when it is copied. (default: false, e.g. true)
  display_name: string # The display name of the template. (e.g. Product Info)
  --fields: list # An ordered list of template fields which are part of the template. Each field can be a regular text field, date field, number field, as well as a single or multi-select list. — item shape: {description?: string, displayName: string, hidden?: bool, key: string, options?: list, type: "string"|"float"|"date"|"enum"|"multiSelect"}
  --hidden: oneof<nothing, bool> # Defines if this template is visible in the Box web app UI, or if it is purely intended for usage through the API. (default: false, e.g. true)
  scope: string # The scope of the metadata template to create. Applications can only create templates for use within the authenticated user's enterprise.  This value needs to be set to `enterprise`, as `global` scopes can not be created by applications. (e.g. enterprise)
  --template-key: string # A unique identifier for the template. This identifier needs to be unique across the enterprise for which the metadata template is being created.  When not provided, the API will create a unique `templateKey` based on the value of the `displayName`. (e.g. productInfo)
]: any -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: list<record>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/schema")
  let body = {"copyInstanceOnItemCopy": $copy_instance_on_item_copy, "displayName": $display_name, "fields": $fields, "hidden": $hidden, "scope": $scope, "templateKey": $template_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add initial classifications
#
# POST /metadata_templates/schema#classifications
# operationId: post_metadata_templates_schema#classifications
# --fields item shape: {displayName?: "Classification", hidden?: bool, key?: "Box__Security__Classification__Key", options?: list, type?: "enum"}
export def "metadata-templates-schemaclassifications schemaclassifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --copy-instance-on-item-copy: oneof<nothing, bool> # `false` (e.g. false)
  display_name: string@display-name-completer # `Classification` (e.g. Classification)
  --fields: list # The classification template holds one field, which holds all the valid classification values. — item shape: {displayName?: "Classification", hidden?: bool, key?: "Box__Security__Classification__Key", options?: list, type?: "enum"}
  --hidden: oneof<nothing, bool> # `false` (e.g. false)
  scope: string@scope-completer-1 # The scope in which to create the classifications. This should be `enterprise` or `enterprise_{id}` where `id` is the unique ID of the enterprise. (e.g. enterprise)
  --template-key: string@template-key-completer # `securityClassification-6VMVochwUWo` (e.g. securityClassification-6VMVochwUWo)
]: any -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/schema#classifications")
  let body = {"copyInstanceOnItemCopy": $copy_instance_on_item_copy, "displayName": $display_name, "fields": $fields, "hidden": $hidden, "scope": $scope, "templateKey": $template_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove metadata template
#
# DELETE /metadata_templates/{scope}/{template_key}/schema
# operationId: delete_metadata_templates_id_id_schema
export def "metadata-templates-schema schema-by-scope-template_key" [
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scope: $scope, template_key: $template_key} | format pattern "/metadata_templates/{scope}/{template_key}/schema"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata template by name
#
# GET /metadata_templates/{scope}/{template_key}/schema
# operationId: get_metadata_templates_id_id_schema
export def "metadata-templates-schema schema-by-scope-template_key-1" [
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: list<record>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scope: $scope, template_key: $template_key} | format pattern "/metadata_templates/{scope}/{template_key}/schema"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update metadata template
#
# PUT /metadata_templates/{scope}/{template_key}/schema
# operationId: put_metadata_templates_id_id_schema
export def "metadata-templates-schema schema-by-scope-template_key-2" [
  scope: string
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: list<record>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scope: $scope, template_key: $template_key} | format pattern "/metadata_templates/{scope}/{template_key}/schema"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Get metadata template by ID
#
# GET /metadata_templates/{template_id}
# operationId: get_metadata_templates_id
export def "metadata-templates id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<copyInstanceOnItemCopy: bool, displayName: string, fields: list<record>, hidden: bool, id: string, scope: string, templateKey: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: $template_id} | format pattern "/metadata_templates/{template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke access token
#
# POST /oauth2/revoke
# operationId: post_oauth2_revoke
export def "oauth2-revoke revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The Client ID of the application requesting to revoke the access token. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --client-secret: string # The client secret of the application requesting to revoke an access token. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  --body-token: string # The access token to revoke. (format: token, e.g. n22JPxrh18m4Y0wIZPIqYZK7VRrsMTWW)
]: any -> record<error: string, error_description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.box.com")
  let full_url = (build-url $base "/oauth2/revoke")
  let body = {"client_id": $client_id, "client_secret": $client_secret, "token": $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Request access token
#
# POST /oauth2/token
# operationId: post_oauth2_token
export def "oauth2-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actor-token: string # The token used to create an annotator token. This is a JWT assertion.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --actor-token-type: string@actor-token-type-completer # The type of `actor_token` passed in.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: urn, e.g. urn:ietf:params:oauth:token-type:id_token)
  --assertion: string # A JWT assertion for which to request a new access token.  Used in combination with `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (format: jwt, e.g. xxxxx.yyyyy.zzzzz)
  --box-shared-link: string # Full URL of the shared link on the file or folder that the token should be generated for. (format: url, e.g. https://cloud.box.com/s/123456)
  --box-subject-id: string # Used in combination with `client_credentials` as the `grant_type`. Value is determined by `box_subject_type`. If `user` use user ID and if `enterprise` use enterprise ID. (e.g. 123456789)
  --box-subject-type: string@box-subject-type-completer # Used in combination with `client_credentials` as the `grant_type`. (e.g. enterprise)
  --client-id: string # The Client ID of the application requesting an access token.  Used in combination with `authorization_code`, `client_credentials`, or `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --client-secret: string # The client secret of the application requesting an access token.  Used in combination with `authorization_code`, `client_credentials`, or `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  --code: string # The client-side authorization code passed to your application by Box in the browser redirect after the user has successfully granted your application permission to make API calls on their behalf.  Used in combination with `authorization_code` as the `grant_type`. (format: token, e.g. n22JPxrh18m4Y0wIZPIqYZK7VRrsMTWW)
  grant_type: string@grant-type-completer # The type of request being made, either using a client-side obtained authorization code, a refresh token, a JWT assertion, client credentials grant or another access token for the purpose of downscoping a token. (format: urn, e.g. authorization_code)
  --refresh-token: string # A refresh token used to get a new access token with.  Used in combination with `refresh_token` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --resource: string # Full URL for the file that the token should be generated for. (format: url, e.g. https://api.box.com/2.0/files/123456)
  --scope: string # The space-delimited list of scopes that you want apply to the new access token.  The `subject_token` will need to have all of these scopes or the call will error with **401 Unauthorized**. (format: space_delimited_list, e.g. item_upload item_preview base_explorer)
  --subject-token: string # The token to exchange for a downscoped token. This can be a regular access token, a JWT assertion, or an app token.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --subject-token-type: string@subject-token-type-completer # The type of `subject_token` passed in.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (e.g. urn:ietf:params:oauth:token-type:access_token)
]: any -> record<access_token: string, expires_in: int, issued_token_type: string, refresh_token: string, restricted_to: table<object: record, scope: string>, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.box.com")
  let full_url = (build-url $base "/oauth2/token")
  let body = {"actor_token": $actor_token, "actor_token_type": $actor_token_type, "assertion": $assertion, "box_shared_link": $box_shared_link, "box_subject_id": $box_subject_id, "box_subject_type": $box_subject_type, "client_id": $client_id, "client_secret": $client_secret, "code": $code, "grant_type": $grant_type, "refresh_token": $refresh_token, "resource": $resource, "scope": $scope, "subject_token": $subject_token, "subject_token_type": $subject_token_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Refresh access token
#
# POST /oauth2/token#refresh
# operationId: post_oauth2_token#refresh
export def "oauth2-tokenrefresh tokenrefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # The client ID of the application requesting to refresh the token. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  client_secret: string # The client secret of the application requesting to refresh the token. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  grant_type: string@grant-type-completer-1 # The type of request being made, in this case a refresh request. (format: urn, e.g. refresh_token)
  refresh_token: string # The refresh token to refresh. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
]: any -> record<access_token: string, expires_in: int, issued_token_type: string, refresh_token: string, restricted_to: table<object: record, scope: string>, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.box.com")
  let full_url = (build-url $base "/oauth2/token#refresh")
  let body = {"client_id": $client_id, "client_secret": $client_secret, "grant_type": $grant_type, "refresh_token": $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List recently accessed items
#
# GET /recent_items
# operationId: get_recent_items
export def "recent-items items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recent_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List retention policies
#
# GET /retention_policies
# operationId: get_retention_policies
export def "retention-policies policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-name: string # Filters results by a case sensitive prefix of the name of retention policies. (e.g. Sales Policy)
  --policy-type: string@policy-type-completer # Filters results by the type of retention policy. (e.g. finite)
  --created-by-user-id: string # Filters results by the ID of the user who created policy. (e.g. 21312321)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_name" $policy_name "scalar") (serialize-qp "policy_type" $policy_type "scalar") (serialize-qp "created_by_user_id" $created_by_user_id "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/retention_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create retention policy
#
# POST /retention_policies
# operationId: post_retention_policies
# --custom_notification_recipients item shape: {id?: string, type: "user", login: string, name: string}
export def "retention-policies policies-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --are-owners-notified: oneof<nothing, bool> # Whether owner and co-owners of a file are notified when the policy nears expiration. (e.g. true)
  --can-owner-extend-retention: oneof<nothing, bool> # Whether the owner of a file will be allowed to extend the retention. (e.g. true)
  --custom-notification-recipients: list # A list of users notified when the retention policy duration is about to end. — item shape: {id?: string, type: "user", login: string, name: string}
  --description: string # The additional text description of the retention policy. (e.g. Policy to retain all reports for at least one month)
  disposition_action: string@disposition-action-completer # The disposition action of the retention policy. `permanently_delete` deletes the content retained by the policy permanently. `remove_retention` lifts retention policy from the content, allowing it to be deleted by users once the retention policy has expired. (e.g. permanently_delete)
  policy_name: string # The name for the retention policy (e.g. Some Policy Name)
  policy_type: string@policy-type-completer # The type of the retention policy. A retention policy type can either be `finite`, where a specific amount of time to retain the content is known upfront, or `indefinite`, where the amount of time to retain the content is still unknown. (e.g. finite)
  --retention-length: string # The length of the retention policy. This value specifies the duration in days that the retention policy will be active for after being assigned to content.  If the policy has a `policy_type` of `indefinite`, the `retention_length` will also be `indefinite`. (format: int32, e.g. 365)
  --retention-type: string@retention-type-completer # Specifies the retention type:  * `modifiable`: You can modify the retention policy. For example, you can add or remove folders, shorten or lengthen the policy duration, or delete the assignment. Use this type if your retention policy is not related to any regulatory purposes.  * `non-modifiable`: You can modify the retention policy only in a limited way: add a folder, lengthen the duration, retire the policy, change the disposition action or notification settings. You cannot perform other actions, such as deleting the assignment or shortening the policy duration. Use this type to ensure compliance with regulatory retention policies. (e.g. modifiable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retention_policies")
  let body = {"are_owners_notified": $are_owners_notified, "can_owner_extend_retention": $can_owner_extend_retention, "custom_notification_recipients": $custom_notification_recipients, "description": $description, "disposition_action": $disposition_action, "policy_name": $policy_name, "policy_type": $policy_type, "retention_length": $retention_length, "retention_type": $retention_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete retention policy
#
# DELETE /retention_policies/{retention_policy_id}
# operationId: delete_retention_policies_id
export def "retention-policies id-by-retention_policy_id" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({retention_policy_id: $retention_policy_id} | format pattern "/retention_policies/{retention_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get retention policy
#
# GET /retention_policies/{retention_policy_id}
# operationId: get_retention_policies_id
export def "retention-policies id-by-retention_policy_id-1" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({retention_policy_id: $retention_policy_id} | format pattern "/retention_policies/{retention_policy_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update retention policy
#
# PUT /retention_policies/{retention_policy_id}
# operationId: put_retention_policies_id
# --custom_notification_recipients item shape: {id?: string, type: "user", login: string, name: string}
export def "retention-policies id-by-retention_policy_id-2" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --are-owners-notified: oneof<nothing, bool> # Determines if owners and co-owners of items under the policy are notified when the retention duration is about to end. (e.g. false)
  --can-owner-extend-retention: oneof<nothing, bool> # Determines if the owner of items under the policy can extend the retention when the original retention duration is about to end. (e.g. false)
  --custom-notification-recipients: list # A list of users notified when the retention duration is about to end. — item shape: {id?: string, type: "user", login: string, name: string}
  --description: string # The additional text description of the retention policy. (e.g. Policy to retain all reports for at least one month)
  --disposition-action: string@disposition-action-completer # The disposition action of the retention policy. `permanently_delete` deletes the content retained by the policy permanently. `remove_retention` lifts retention policy from the content, allowing it to be deleted by users once the retention policy has expired. (e.g. permanently_delete)
  --policy-name: string # The name for the retention policy (e.g. Some Policy Name)
  --retention-length: string # The length of the retention policy. This value specifies the duration in days that the retention policy will be active for after being assigned to content.  If the policy has a `policy_type` of `indefinite`, the `retention_length` will also be `indefinite`. (format: int32, e.g. 365)
  --retention-type: string # Specifies the retention type:  * `modifiable`: You can modify the retention policy. For example, you can add or remove folders, shorten or lengthen the policy duration, or delete the assignment. Use this type if your retention policy is not related to any regulatory purposes. * `non-modifiable`: You can modify the retention policy only in a limited way: add a folder, lengthen the duration, retire the policy, change the disposition action or notification settings. You cannot perform other actions, such as deleting the assignment or shortening the policy duration. Use this type to ensure compliance with regulatory retention policies.  When updating a retention policy, you can use `non-modifiable` type only. You can convert a `modifiable` policy to `non-modifiable`, but not the other way around. (e.g. non-modifiable)
  --status: string # Used to retire a retention policy.  If not retiring a policy, do not include this parameter or set it to `null`. (e.g. retired)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({retention_policy_id: $retention_policy_id} | format pattern "/retention_policies/{retention_policy_id}"))
  let body = {"are_owners_notified": $are_owners_notified, "can_owner_extend_retention": $can_owner_extend_retention, "custom_notification_recipients": $custom_notification_recipients, "description": $description, "disposition_action": $disposition_action, "policy_name": $policy_name, "retention_length": $retention_length, "retention_type": $retention_type, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List retention policy assignments
#
# GET /retention_policies/{retention_policy_id}/assignments
# operationId: get_retention_policies_id_assignments
export def "retention-policies-assignments assignments" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The type of the retention policy assignment to retrieve. (e.g. metadata_template)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({retention_policy_id: $retention_policy_id} | format pattern "/retention_policies/{retention_policy_id}/assignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign retention policy
#
# POST /retention_policy_assignments
# operationId: post_retention_policy_assignments
# --assign_to shape: {id: string, type: "enterprise"|"folder"|"metadata_template"}
# --filter_fields item shape: {field?: string, value?: string}
export def "retention-policy-assignments assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assign_to: record # The item to assign the policy to — shape: {id: string, type: "enterprise"|"folder"|"metadata_template"}
  --filter-fields: list # If the `assign_to` type is `metadata_template`, then optionally add the `filter_fields` parameter which will require an array of objects with a field entry and a value entry. Currently only one object of `field` and `value` is supported. — item shape: {field?: string, value?: string}
  policy_id: string # The ID of the retention policy to assign (e.g. 173463)
  --start-date-field: string # The date the retention policy assignment begins.  If the `assigned_to` type is `metadata_template`, this field can be a date field's metadata attribute key id. (e.g. upload_date)
]: any -> record<assigned_at: string, assigned_by: record, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, id: string, retention_policy: record, start_date_field: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retention_policy_assignments")
  let body = {"assign_to": $assign_to, "filter_fields": $filter_fields, "policy_id": $policy_id, "start_date_field": $start_date_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove retention policy assignment
#
# DELETE /retention_policy_assignments/{retention_policy_assignment_id}
# operationId: delete_retention_policy_assignments_id
export def "retention-policy-assignments id-by-retention_policy_assignment_id" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({retention_policy_assignment_id: $retention_policy_assignment_id} | format pattern "/retention_policy_assignments/{retention_policy_assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get retention policy assignment
#
# GET /retention_policy_assignments/{retention_policy_assignment_id}
# operationId: get_retention_policy_assignments_id
export def "retention-policy-assignments id-by-retention_policy_assignment_id-1" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<assigned_at: string, assigned_by: record, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, id: string, retention_policy: record, start_date_field: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({retention_policy_assignment_id: $retention_policy_assignment_id} | format pattern "/retention_policy_assignments/{retention_policy_assignment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file versions under retention
#
# GET /retention_policy_assignments/{retention_policy_assignment_id}/file_versions_under_retention
# operationId: get_retention_policy_assignments_id_file_versions_under_retention
export def "retention-policy-assignments-file-versions-under-retention retention" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({retention_policy_assignment_id: $retention_policy_assignment_id} | format pattern "/retention_policy_assignments/{retention_policy_assignment_id}/file_versions_under_retention") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get files under retention
#
# GET /retention_policy_assignments/{retention_policy_assignment_id}/files_under_retention
# operationId: get_retention_policy_assignments_id_files_under_retention
export def "retention-policy-assignments-files-under-retention retention" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({retention_policy_assignment_id: $retention_policy_assignment_id} | format pattern "/retention_policy_assignments/{retention_policy_assignment_id}/files_under_retention") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for content
#
# GET /search
# operationId: get_search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The string to search for. This query is matched against item names, descriptions, text content of files, and various other fields of the different item types.  This parameter supports a variety of operators to further refine the results returns.  * `""` - by wrapping a query in double quotes only exact matches are   returned by the API. Exact searches do not return search matches   based on specific character sequences. Instead, they return   matches based on phrases, that is, word sequences. For example:   A search for `"Blue-Box"` may return search results including   the sequence `"blue.box"`, `"Blue Box"`, and `"Blue-Box"`;   any item containing the words `Blue` and `Box` consecutively, in   the order specified. * `AND` - returns items that contain both the search terms. For   example, a search for `marketing AND BoxWorks` returns items   that have both `marketing` and `BoxWorks` within its text in any order.   It does not return a result that only has `BoxWorks` in its text. * `OR` - returns items that contain either of the search terms. For   example, a search for `marketing OR BoxWorks` returns a result that   has either `marketing` or `BoxWorks` within its text. Using this   operator is not necessary as we implicitly interpret multi-word   queries as `OR` unless another supported boolean term is used. * `NOT` - returns items that do not contain the search term provided.   For example, a search for `marketing AND NOT BoxWorks` returns a result   that has only `marketing` within its text. Results containing   `BoxWorks` are omitted.  Please note that we do not support lower case (that is, `and`, `or`, and `not`) or mixed case (that is, `And`, `Or`, and `Not`) operators.  This field is required unless the `mdfilters` parameter is defined. (e.g. sales)
  --scope: string@scope-completer-2 # Limits the search results to either the files that the user has access to, or to files available to the entire enterprise.  The scope defaults to `user_content`, which limits the search results to content that is available to the currently authenticated user.  The `enterprise_content` can be requested by an admin through our support channels. Once this scope has been enabled for a user, it will allow that use to query for content across the entire enterprise and not only the content that they have access to. (default: user_content, e.g. user_content)
  --file-extensions: list # Limits the search results to any files that match any of the provided file extensions. This list is a comma-separated list of file extensions without the dots. (e.g. [pdf, png, gif])
  --created-at-range: list # Limits the search results to any items created within a given date range.  Date ranges are defined as comma separated RFC3339 timestamps.  If the the start date is omitted (`,2014-05-17T13:35:01-07:00`) anything created before the end date will be returned.  If the end date is omitted (`2014-05-15T13:35:01-07:00,`) the current date will be used as the end date instead. (e.g. [2014-05-15T13:35:01-07:00, 2014-05-17T13:35:01-07:00])
  --updated-at-range: list # Limits the search results to any items updated within a given date range.  Date ranges are defined as comma separated RFC3339 timestamps.  If the start date is omitted (`,2014-05-17T13:35:01-07:00`) anything updated before the end date will be returned.  If the end date is omitted (`2014-05-15T13:35:01-07:00,`) the current date will be used as the end date instead. (e.g. [2014-05-15T13:35:01-07:00, 2014-05-17T13:35:01-07:00])
  --size-range: list # Limits the search results to any items with a size within a given file size range. This applied to files and folders.  Size ranges are defined as comma separated list of a lower and upper byte size limit (inclusive).  The upper and lower bound can be omitted to create open ranges. (e.g. [1000000, 5000000])
  --owner-user-ids: list # Limits the search results to any items that are owned by the given list of owners, defined as a list of comma separated user IDs.  Please note that the items still need to be owned or shared with the currently authenticated user for them to show up in the search results. If the user does not have access to any files owned by any of the users an empty result set will be returned.  To search across an entire enterprise, we recommend using the `enterprise_content` scope parameter which can be requested with our support team. (e.g. [123422, 23532, 3241212])
  --recent-updater-user-ids: list # Limits the search results to any items that have been updated by the given list of users, defined as a list of comma separated user IDs.  Please note that the items still need to be owned or shared with the currently authenticated user for them to show up in the search results. If the user does not have access to any files owned by any of the users an empty result set will be returned.  This feature only searches back to the last 10 versions of an item. (e.g. [123422, 23532, 3241212])
  --ancestor-folder-ids: list # Limits the search results to items within the given list of folders, defined as a comma separated lists of folder IDs.  Search results will also include items within any subfolders of those ancestor folders.  Please note that the folders still need to be owned or shared with the currently authenticated user. If the folder is not accessible by this user, or it does not exist, a `HTTP 404` error code will be returned instead.  To search across an entire enterprise, we recommend using the `enterprise_content` scope parameter which can be requested with our support team. (e.g. [4535234, 234123235, 2654345])
  --content-types: list # Limits the search results to any items that match the search query for a specific part of the file, for example the file description.  Content types are defined as a comma separated lists of Box recognized content types. The allowed content types are as follows.  * `name` - The name of the item, as defined by its `name` field. * `description` - The description of the item, as defined by its   `description` field. * `file_content` - The actual content of the file. * `comments` - The content of any of the comments on a file or    folder. * `tags` - Any tags that are applied to an item, as defined by its    `tags` field. (e.g. [name, description])
  --type: string@type-completer-2 # Limits the search results to any items of this type. This parameter only takes one value. By default the API returns items that match any of these types.  * `file` - Limits the search results to files * `folder` - Limits the search results to folders * `web_link` - Limits the search results to web links, also known    as bookmarks (e.g. file)
  --trash-content: string@trash-content-completer # Determines if the search should look in the trash for items.  By default, this API only returns search results for items not currently in the trash (`non_trashed_only`).  * `trashed_only` - Only searches for items currently in the trash * `non_trashed_only` - Only searches for items currently not in   the trash (default: non_trashed_only, e.g. non_trashed_only)
  --mdfilters: list # Limits the search results to any items for which the metadata matches the provided filter.  This parameter contains a list of 1 metadata template to filter the search results by. This list can currently only contain one entry, though this might be expanded in the future.  This parameter is required unless the `query` parameter is provided. (e.g. [{filters: {category: online}, scope: enterprise, templateKey: contract}])
  --qp-sort: string@sort-completer-1 # Defines the order in which search results are returned. This API defaults to returning items by relevance unless this parameter is explicitly specified.  * `relevance` (default) returns the results sorted by relevance to the query search term. The relevance is based on the occurrence of the search term in the items name, description, content, and additional properties. * `modified_at` returns the results ordered in descending order by date at which the item was last modified. (default: relevance, e.g. modified_at)
  --direction: string@direction-completer-1 # Defines the direction in which search results are ordered. This API defaults to returning items in descending (`DESC`) order unless this parameter is explicitly specified.  When results are sorted by `relevance` the ordering is locked to returning items in descending order of relevance, and this parameter is ignored. (default: DESC, e.g. ASC)
  --limit: int # Defines the maximum number of items to return as part of a page of results. (format: int64, default: 30, e.g. 100)
  --include-recent-shared-links: oneof<nothing, bool> # Defines whether the search results should include any items that the user recently accessed through a shared link.  Please note that when this parameter has been set to true, the format of the response of this API changes to return a list of [Search Results with Shared Links](r://search_results_with_shared_links) (default: false, e.g. true)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "file_extensions" $file_extensions "csv") (serialize-qp "created_at_range" $created_at_range "csv") (serialize-qp "updated_at_range" $updated_at_range "csv") (serialize-qp "size_range" $size_range "csv") (serialize-qp "owner_user_ids" $owner_user_ids "csv") (serialize-qp "recent_updater_user_ids" $recent_updater_user_ids "csv") (serialize-qp "ancestor_folder_ids" $ancestor_folder_ids "csv") (serialize-qp "content_types" $content_types "csv") (serialize-qp "type" $type "scalar") (serialize-qp "trash_content" $trash_content "scalar") (serialize-qp "mdfilters" $mdfilters "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include_recent_shared_links" $include_recent_shared_links "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find file for shared link
#
# GET /shared_items
# operationId: get_shared_items
export def "shared-items items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link.  The format for this header is as follows.  `shared_link=[link]&shared_link_password=[password]` (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_items" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find folder for shared link
#
# GET /shared_items#folders
# operationId: get_shared_items#folders
export def "shared-itemsfolders itemsfolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link.  The format for this header is as follows.  `shared_link=[link]&shared_link_password=[password]` (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_items#folders" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find web link for shared link
#
# GET /shared_items#web_links
# operationId: get_shared_items#web_links
export def "shared-itemsweb-links links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link.  The format for this header is as follows.  `shared_link=[link]&shared_link_password=[password]` (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_items#web_links" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List shield information barrier reports
#
# GET /shield_information_barrier_reports
# operationId: get_shield_information_barrier_reports
export def "shield-information-barrier-reports reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-id: string # The ID of the shield information barrier. (e.g. 1910967)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record<entries: list<record>, limit: int, next_marker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_id" $shield_information_barrier_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create shield information barrier report
#
# POST /shield_information_barrier_reports
# operationId: post_shield_information_barrier_reports
# --shield_information_barrier shape: {id?: string, type?: "shield_information_barrier"}
export def "shield-information-barrier-reports reports-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_reports")
  let body = {"shield_information_barrier": $shield_information_barrier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get shield information barrier report by ID
#
# GET /shield_information_barrier_reports/{shield_information_barrier_report_id}
# operationId: get_shield_information_barrier_reports_id
export def "shield-information-barrier-reports id" [
  shield_information_barrier_report_id: string
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
  let full_url = (build-url $base ({shield_information_barrier_report_id: $shield_information_barrier_report_id} | format pattern "/shield_information_barrier_reports/{shield_information_barrier_report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List shield information barrier segment members
#
# GET /shield_information_barrier_segment_members
# operationId: get_shield_information_barrier_segment_members
export def "shield-information-barrier-segment-members members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-segment-id: string # The ID of the shield information barrier segment. (e.g. 3423)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record<entries: list<record>, limit: int, next_marker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_segment_id" $shield_information_barrier_segment_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_segment_members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create shield information barrier segment member
#
# POST /shield_information_barrier_segment_members
# operationId: post_shield_information_barrier_segment_members
# --shield_information_barrier shape: {id?: string, type?: "shield_information_barrier"}
# --shield_information_barrier_segment shape: {id?: string, type?: "shield_information_barrier_segment"}
export def "shield-information-barrier-segment-members members-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
  shield_information_barrier_segment: record # The `type` and `id` of the requested shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  --type: string@type-completer-3 # -| A type of the shield barrier segment member. (e.g. shield_information_barrier_segment_member)
  user: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_segment_members")
  let body = {"shield_information_barrier": $shield_information_barrier, "shield_information_barrier_segment": $shield_information_barrier_segment, "type": $type, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete shield information barrier segment member by ID
#
# DELETE /shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}
# operationId: delete_shield_information_barrier_segment_members_id
export def "shield-information-barrier-segment-members id-by-shield_information_barrier_segment_member_id" [
  shield_information_barrier_segment_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shield_information_barrier_segment_member_id: $shield_information_barrier_segment_member_id} | format pattern "/shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shield information barrier segment member by ID
#
# GET /shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}
# operationId: get_shield_information_barrier_segment_members_id
export def "shield-information-barrier-segment-members id-by-shield_information_barrier_segment_member_id-1" [
  shield_information_barrier_segment_member_id: string
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
  let full_url = (build-url $base ({shield_information_barrier_segment_member_id: $shield_information_barrier_segment_member_id} | format pattern "/shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List shield information barrier segment restrictions
#
# GET /shield_information_barrier_segment_restrictions
# operationId: get_shield_information_barrier_segment_restrictions
export def "shield-information-barrier-segment-restrictions restrictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-segment-id: string # The ID of the shield information barrier segment. (e.g. 3423)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record<entries: list<record>, limit: int, next_marker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_segment_id" $shield_information_barrier_segment_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_segment_restrictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create shield information barrier segment restriction
#
# POST /shield_information_barrier_segment_restrictions
# operationId: post_shield_information_barrier_segment_restrictions
# --restricted_segment shape: {id?: string, type?: "shield_information_barrier_segment"}
# --shield_information_barrier shape: {id?: string, type?: "shield_information_barrier"}
# --shield_information_barrier_segment shape: {id?: string, type?: "shield_information_barrier_segment"}
export def "shield-information-barrier-segment-restrictions restrictions-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  restricted_segment: record # The `type` and `id` of the restricted shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  --shield-information-barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
  shield_information_barrier_segment: record # The `type` and `id` of the requested shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  type: string@type-completer-4 # The type of the shield barrier segment restriction for this member. (e.g. shield_information_barrier_segment_restriction)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_segment_restrictions")
  let body = {"restricted_segment": $restricted_segment, "shield_information_barrier": $shield_information_barrier, "shield_information_barrier_segment": $shield_information_barrier_segment, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete shield information barrier segment restriction by ID
#
# DELETE /shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}
# operationId: delete_shield_information_barrier_segment_restrictions_id
export def "shield-information-barrier-segment-restrictions id-by-shield_information_barrier_segment_restriction_id" [
  shield_information_barrier_segment_restriction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shield_information_barrier_segment_restriction_id: $shield_information_barrier_segment_restriction_id} | format pattern "/shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shield information barrier segment restriction by ID
#
# GET /shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}
# operationId: get_shield_information_barrier_segment_restrictions_id
export def "shield-information-barrier-segment-restrictions id-by-shield_information_barrier_segment_restriction_id-1" [
  shield_information_barrier_segment_restriction_id: string
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
  let full_url = (build-url $base ({shield_information_barrier_segment_restriction_id: $shield_information_barrier_segment_restriction_id} | format pattern "/shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List shield information barrier segments
#
# GET /shield_information_barrier_segments
# operationId: get_shield_information_barrier_segments
export def "shield-information-barrier-segments segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-id: string # The ID of the shield information barrier. (e.g. 1910967)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record<entries: table<created_at: string, created_by: record, description: string, id: string, name: string, shield_information_barrier: record, type: string, updated_at: string, updated_by: record>, limit: int, next_marker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_id" $shield_information_barrier_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create shield information barrier segment
#
# POST /shield_information_barrier_segments
# operationId: post_shield_information_barrier_segments
# --shield_information_barrier shape: {id?: string, type?: "shield_information_barrier"}
export def "shield-information-barrier-segments segments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the shield information barrier segment (e.g. 'Corporate division that engages in  advisory_based financial transactions on behalf of individuals, corporations, and governments.')
  name: string # Name of the shield information barrier segment (e.g. Investment Banking)
  shield_information_barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
]: any -> record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_segments")
  let body = {"description": $description, "name": $name, "shield_information_barrier": $shield_information_barrier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete shield information barrier segment
#
# DELETE /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# operationId: delete_shield_information_barrier_segments_id
export def "shield-information-barrier-segments id-by-shield_information_barrier_segment_id" [
  shield_information_barrier_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shield_information_barrier_segment_id: $shield_information_barrier_segment_id} | format pattern "/shield_information_barrier_segments/{shield_information_barrier_segment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shield information barrier segment with specified ID
#
# GET /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# operationId: get_shield_information_barrier_segments_id
export def "shield-information-barrier-segments id-by-shield_information_barrier_segment_id-1" [
  shield_information_barrier_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shield_information_barrier_segment_id: $shield_information_barrier_segment_id} | format pattern "/shield_information_barrier_segments/{shield_information_barrier_segment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update shield information barrier segment with specified ID
#
# PUT /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# operationId: put_shield_information_barrier_segments_id
export def "shield-information-barrier-segments id-by-shield_information_barrier_segment_id-2" [
  shield_information_barrier_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The updated description for the shield information barrier segment. (nullable, e.g. 'Corporate division that engages in advisory_based financial transactions on behalf of individuals, corporations, and governments.')
  --name: string # The updated name for the shield information barrier segment. (e.g. Investment Banking)
]: any -> record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shield_information_barrier_segment_id: $shield_information_barrier_segment_id} | format pattern "/shield_information_barrier_segments/{shield_information_barrier_segment_id}"))
  let body = {"description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List shield information barriers
#
# GET /shield_information_barriers
# operationId: get_shield_information_barriers
export def "shield-information-barriers barriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record<entries: table<created_at: string, created_by: record, enabled_at: string, enabled_by: record, enterprise: record, id: string, status: string, type: string, updated_at: string, updated_by: record>, limit: int, next_marker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barriers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create shield information barrier
#
# POST /shield_information_barriers
# operationId: post_shield_information_barriers
export def "shield-information-barriers barriers-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # ISO date time string when this shield information barrier object was created. (format: date-time, e.g. 2020-06-26T18:44:45.869Z)
  --created-by: any
  --enabled-at: string # ISO date time string when this shield information barrier was enabled. (format: date-time, e.g. 2020-07-26T18:44:45.869Z)
  --enabled-by: any
  --enterprise: any
  --id: string # The unique identifier for the shield information barrier (e.g. 11446498)
  --status: string@status-completer-3 # Status of the shield information barrier (e.g. draft)
  --type: string@type-completer-5 # The type of the shield information barrier (e.g. shield_information_barrier)
  --updated-at: string # ISO date time string when this shield information barrier was updated. (format: date-time, e.g. 2020-07-26T18:44:45.869Z)
  --updated-by: any
]: any -> record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barriers")
  let body = {"created_at": $created_at, "created_by": $created_by, "enabled_at": $enabled_at, "enabled_by": $enabled_by, "enterprise": $enterprise, "id": $id, "status": $status, "type": $type, "updated_at": $updated_at, "updated_by": $updated_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add changed status of shield information barrier with specified ID
#
# POST /shield_information_barriers/change_status
# operationId: post_shield_information_barriers_change_status
export def "shield-information-barriers-change-status status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the shield information barrier. (e.g. 1910967)
  status: string@status-completer-4 # The desired status for the shield information barrier. (e.g. pending)
]: any -> record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barriers/change_status")
  let body = {"id": $id, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get shield information barrier with specified ID
#
# GET /shield_information_barriers/{shield_information_barrier_id}
# operationId: get_shield_information_barriers_id
export def "shield-information-barriers id" [
  shield_information_barrier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shield_information_barrier_id: $shield_information_barrier_id} | format pattern "/shield_information_barriers/{shield_information_barrier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sign requests
#
# GET /sign_requests
# operationId: get_sign_requests
export def "sign-requests request-s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sign_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create sign request
#
# POST /sign_requests
# operationId: post_sign_requests
# --prefill_tags item shape: {checkbox_value?: bool, date_value?: string, document_tag_id?: string, text_value?: string}
# --signers item shape: {declined_redirect_url?: string, email: string, embed_url_external_user_id?: string, is_in_person?: bool, login_required?: bool, order?: int, password?: string, redirect_url?: string, role?: "signer"|"approver"|"final_copy_reader", verification_phone_number?: string}
# --source_files item shape: {etag?: string, id: string, type: "file", file_version?: any, name?: string, sequence_id: any, sha1: string}
export def "sign-requests request-s-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --are-reminders-enabled: oneof<nothing, bool> # Reminds signers to sign a document on day 3, 8, 13 and 18. Reminders are only sent to outstanding signers. (e.g. true)
  --are-text-signatures-enabled: oneof<nothing, bool> # Disables the usage of signatures generated by typing (text). (default: true, e.g. true)
  --days-valid: int # Number of days after which this request will automatically expire if not completed. (nullable, e.g. 2)
  --declined-redirect-url: string # The uri that a signer will be redirected to after declining to sign a document. (nullable, e.g. https://declined-redirect.com)
  --email-message: string # Message to include in sign request email. The field is cleaned through sanitization of specific characters. However, some html tags are allowed. Links included in the message are also converted to hyperlinks in the email. The message may contain the following html tags including `a`, `abbr`, `acronym`, `b`, `blockquote`, `code`, `em`, `i`, `ul`, `li`, `ol`, and `strong`. Be aware that when the text to html ratio is too high, the email may end up in spam filters. Custom styles on these tags are not allowed. If this field is not passed, a default message will be used. (nullable, e.g. Hello! Please sign the document below)
  --email-subject: string # Subject of sign request email. This is cleaned by sign request. If this field is not passed, a default subject will be used. (nullable, e.g. Sign Request from Acme)
  --external-id: string # This can be used to reference an ID in an external system that the sign request is related to. (nullable, e.g. 123)
  --is-document-preparation-needed: oneof<nothing, bool> # Indicates if the sender should receive a `prepare_url` in the response to complete document preparation via UI. (e.g. true)
  --is-phone-verification-required-to-view: oneof<nothing, bool> # Forces signers to verify a text message prior to viewing the document. You must specify the phone number of signers to have this setting apply to them. (nullable, e.g. true)
  --name: string # Name of the sign request. (e.g. name)
  parent_folder: any
  --prefill-tags: list # When a document contains sign related tags in the content, you can prefill them using this `prefill_tags` by referencing the 'id' of the tag as the `external_id` field of the prefill tag. — item shape: {checkbox_value?: bool, date_value?: string, document_tag_id?: string, text_value?: string}
  --redirect-url: string # When specified, signature request will be redirected to this url when a document is signed. (nullable, e.g. https://www.example.com)
  --signature-color: string@signature-color-completer # Force a specific signature color (blue, black, or red). (nullable, e.g. blue)
  signers: list # Array of signers for the sign request. 35 is the max number of signers permitted. — item shape: {declined_redirect_url?: string, email: string, embed_url_external_user_id?: string, is_in_person?: bool, login_required?: bool, order?: int, password?: string, redirect_url?: string, role?: "signer"|"approver"|"final_copy_reader", verification_phone_number?: string}
  source_files: list # List of files to create a signing document from. This is currently limited to 10 files. Only the ID and type fields are required for each file. The array will be empty if the `source_files` are deleted. — item shape: {etag?: string, id: string, type: "file", file_version?: any, name?: string, sequence_id: any, sha1: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sign_requests")
  let body = {"are_reminders_enabled": $are_reminders_enabled, "are_text_signatures_enabled": $are_text_signatures_enabled, "days_valid": $days_valid, "declined_redirect_url": $declined_redirect_url, "email_message": $email_message, "email_subject": $email_subject, "external_id": $external_id, "is_document_preparation_needed": $is_document_preparation_needed, "is_phone_verification_required_to_view": $is_phone_verification_required_to_view, "name": $name, "parent_folder": $parent_folder, "prefill_tags": $prefill_tags, "redirect_url": $redirect_url, "signature_color": $signature_color, "signers": $signers, "source_files": $source_files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sign request by ID
#
# GET /sign_requests/{sign_request_id}
# operationId: get_sign_requests_id
export def "sign-requests id" [
  sign_request_id: string
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
  let full_url = (build-url $base ({sign_request_id: $sign_request_id} | format pattern "/sign_requests/{sign_request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel sign request
#
# POST /sign_requests/{sign_request_id}/cancel
# operationId: post_sign_requests_id_cancel
export def "sign-requests-cancel cancel" [
  sign_request_id: string
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
  let full_url = (build-url $base ({sign_request_id: $sign_request_id} | format pattern "/sign_requests/{sign_request_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend sign request
#
# POST /sign_requests/{sign_request_id}/resend
# operationId: post_sign_requests_id_resend
export def "sign-requests-resend resend" [
  sign_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sign_request_id: $sign_request_id} | format pattern "/sign_requests/{sign_request_id}/resend"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update all Box Skill cards on file
#
# PUT /skill_invocations/{skill_id}
# operationId: put_skill_invocations_id
# --file shape: {id?: string, type?: "file"}
# --file_version shape: {id?: string, type?: "file_version"}
# --metadata shape: {cards?: list}
# --usage shape: {unit?: string, value?: float}
export def "skill-invocations id" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: record # The file to assign the cards to. — shape: {id?: string, type?: "file"}
  --file-version: record # The optional file version to assign the cards to. — shape: {id?: string, type?: "file_version"}
  metadata: record # The metadata to set for this skill. This is a list of Box Skills cards. These cards will overwrite any existing Box skill cards on the file. — shape: {cards?: list}
  status: string@status-completer-5 # Defines the status of this invocation. Set this to `success` when setting Skill cards. (e.g. success)
  --usage: record # A descriptor that defines what items are affected by this call.  Set this to the default values when setting a card to a `success` state, and leave it out in most other situations. — shape: {unit?: string, value?: float}
]: any -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({skill_id: $skill_id} | format pattern "/skill_invocations/{skill_id}"))
  let body = {"file": $file, "file_version": $file_version, "metadata": $metadata, "status": $status, "usage": $usage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List storage policies
#
# GET /storage_policies
# operationId: get_storage_policies
export def "storage-policies policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get storage policy
#
# GET /storage_policies/{storage_policy_id}
# operationId: get_storage_policies_id
export def "storage-policies id" [
  storage_policy_id: string
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
  let full_url = (build-url $base ({storage_policy_id: $storage_policy_id} | format pattern "/storage_policies/{storage_policy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List storage policy assignments
#
# GET /storage_policy_assignments
# operationId: get_storage_policy_assignments
export def "storage-policy-assignments assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --resolved-for-type: string@resolved-for-type-completer # The target type to return assignments for (e.g. user)
  --resolved-for-id: string # The ID of the user or enterprise to return assignments for (e.g. 984322)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "resolved_for_type" $resolved_for_type "scalar") (serialize-qp "resolved_for_id" $resolved_for_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage_policy_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign storage policy
#
# POST /storage_policy_assignments
# operationId: post_storage_policy_assignments
# --assigned_to shape: {id: string, type: "user"|"enterprise"}
# --storage_policy shape: {id: string, type: "storage_policy"}
export def "storage-policy-assignments assignments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assigned_to: record # The user or enterprise to assign the storage policy to. — shape: {id: string, type: "user"|"enterprise"}
  storage_policy: record # The storage policy to assign to the user or enterprise — shape: {id: string, type: "storage_policy"}
]: any -> record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storage_policy_assignments")
  let body = {"assigned_to": $assigned_to, "storage_policy": $storage_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unassign storage policy
#
# DELETE /storage_policy_assignments/{storage_policy_assignment_id}
# operationId: delete_storage_policy_assignments_id
export def "storage-policy-assignments id-by-storage_policy_assignment_id" [
  storage_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storage_policy_assignment_id: $storage_policy_assignment_id} | format pattern "/storage_policy_assignments/{storage_policy_assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get storage policy assignment
#
# GET /storage_policy_assignments/{storage_policy_assignment_id}
# operationId: get_storage_policy_assignments_id
export def "storage-policy-assignments id-by-storage_policy_assignment_id-1" [
  storage_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storage_policy_assignment_id: $storage_policy_assignment_id} | format pattern "/storage_policy_assignments/{storage_policy_assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update storage policy assignment
#
# PUT /storage_policy_assignments/{storage_policy_assignment_id}
# operationId: put_storage_policy_assignments_id
# --storage_policy shape: {id: string, type: "storage_policy"}
export def "storage-policy-assignments id-by-storage_policy_assignment_id-2" [
  storage_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  storage_policy: record # The storage policy to assign to the user or enterprise — shape: {id: string, type: "storage_policy"}
]: any -> record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({storage_policy_assignment_id: $storage_policy_assignment_id} | format pattern "/storage_policy_assignments/{storage_policy_assignment_id}"))
  let body = {"storage_policy": $storage_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Assign task
#
# POST /task_assignments
# operationId: post_task_assignments
# --assign_to shape: {id?: string, login?: string}
# --task shape: {id: string, type: "task"}
export def "task-assignments assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assign_to: record # The user to assign the task to. — shape: {id?: string, login?: string}
  task: record # The task to assign to a user. — shape: {id: string, type: "task"}
]: any -> record<assigned_at: string, assigned_by: record, assigned_to: record, completed_at: string, id: string, item: record, message: string, reminded_at: string, resolution_state: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/task_assignments")
  let body = {"assign_to": $assign_to, "task": $task} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unassign task
#
# DELETE /task_assignments/{task_assignment_id}
# operationId: delete_task_assignments_id
export def "task-assignments id-by-task_assignment_id" [
  task_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_assignment_id: $task_assignment_id} | format pattern "/task_assignments/{task_assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task assignment
#
# GET /task_assignments/{task_assignment_id}
# operationId: get_task_assignments_id
export def "task-assignments id-by-task_assignment_id-1" [
  task_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assigned_at: string, assigned_by: record, assigned_to: record, completed_at: string, id: string, item: record, message: string, reminded_at: string, resolution_state: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_assignment_id: $task_assignment_id} | format pattern "/task_assignments/{task_assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update task assignment
#
# PUT /task_assignments/{task_assignment_id}
# operationId: put_task_assignments_id
export def "task-assignments id-by-task_assignment_id-2" [
  task_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # An optional message by the assignee that can be added to the task. (e.g. Looks good to me)
  --resolution-state: string@resolution-state-completer # The state of the task assigned to the user.  * For a task with an `action` value of `complete` this can be `incomplete` or `completed`. * For a task with an `action` of `review` this can be `incomplete`, `approved`, or `rejected`. (e.g. completed)
]: any -> record<assigned_at: string, assigned_by: record, assigned_to: record, completed_at: string, id: string, item: record, message: string, reminded_at: string, resolution_state: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_assignment_id: $task_assignment_id} | format pattern "/task_assignments/{task_assignment_id}"))
  let body = {"message": $message, "resolution_state": $resolution_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create task
#
# POST /tasks
# operationId: post_tasks
# --item shape: {id: string, type: "file"}
export def "tasks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # The action the task assignee will be prompted to do. Must be  * `review` defines an approval task that can be approved or rejected * `complete` defines a general task which can be completed (default: review, e.g. review)
  --completion-rule: string@completion-rule-completer # Defines which assignees need to complete this task before the task is considered completed.  * `all_assignees` (default) requires all assignees to review or approve the the task in order for it to be considered completed. * `any_assignee` accepts any one assignee to review or approve the the task in order for it to be considered completed. (default: all_assignees, e.g. all_assignees)
  --due-at: string # Defines when the task is due. Defaults to `null` if not provided. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  item: record # The file to attach the task to. — shape: {id: string, type: "file"}
  --message: string # An optional message to include with the task. (default: , e.g. Please review)
]: any -> record<action: string, completion_rule: string, created_at: string, created_by: record, due_at: string, id: string, is_completed: bool, item: record, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks")
  let body = {"action": $action, "completion_rule": $completion_rule, "due_at": $due_at, "item": $item, "message": $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove task
#
# DELETE /tasks/{task_id}
# operationId: delete_tasks_id
export def "tasks id-by-task_id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task
#
# GET /tasks/{task_id}
# operationId: get_tasks_id
export def "tasks id-by-task_id-1" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, completion_rule: string, created_at: string, created_by: record, due_at: string, id: string, is_completed: bool, item: record, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update task
#
# PUT /tasks/{task_id}
# operationId: put_tasks_id
export def "tasks id-by-task_id-2" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # The action the task assignee will be prompted to do. Must be  * `review` defines an approval task that can be approved or rejected * `complete` defines a general task which can be completed (e.g. review)
  --completion-rule: string@completion-rule-completer # Defines which assignees need to complete this task before the task is considered completed.  * `all_assignees` (default) requires all assignees to review or approve the the task in order for it to be considered completed. * `any_assignee` accepts any one assignee to review or approve the the task in order for it to be considered completed. (e.g. all_assignees)
  --due-at: string # When the task is due at. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --message: string # The message included with the task. (e.g. Please review)
]: any -> record<action: string, completion_rule: string, created_at: string, created_by: record, due_at: string, id: string, is_completed: bool, item: record, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}"))
  let body = {"action": $action, "completion_rule": $completion_rule, "due_at": $due_at, "message": $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List task assignments
#
# GET /tasks/{task_id}/assignments
# operationId: get_tasks_id_assignments
export def "tasks-assignments assignments" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entries: table<assigned_at: string, assigned_by: record, assigned_to: record, completed_at: string, id: string, item: record, message: string, reminded_at: string, resolution_state: string, type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/tasks/{task_id}/assignments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List terms of service user statuses
#
# GET /terms_of_service_user_statuses
# operationId: get_terms_of_service_user_statuses
export def "terms-of-service-user-statuses statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tos-id: string # The ID of the terms of service. (e.g. 324234)
  --user-id: string # Limits results to the given user ID. (e.g. 123334)
]: nothing -> record<entries: table<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record, type: string, user: record>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tos_id" $tos_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/terms_of_service_user_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create terms of service status for new user
#
# POST /terms_of_service_user_statuses
# operationId: post_terms_of_service_user_statuses
# --tos shape: {id: string, type: "terms_of_service"}
# --user shape: {id: string, type: "user"}
export def "terms-of-service-user-statuses statuses-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-accepted: oneof<nothing, bool> # Whether the user has accepted the terms. (e.g. true)
  tos: record # The terms of service to set the status for. — shape: {id: string, type: "terms_of_service"}
  user: record # The user to set the status for. — shape: {id: string, type: "user"}
]: any -> record<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record<id: string, type: string>, type: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/terms_of_service_user_statuses")
  let body = {"is_accepted": $is_accepted, "tos": $tos, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update terms of service status for existing user
#
# PUT /terms_of_service_user_statuses/{terms_of_service_user_status_id}
# operationId: put_terms_of_service_user_statuses_id
export def "terms-of-service-user-statuses id" [
  terms_of_service_user_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-accepted: oneof<nothing, bool> # Whether the user has accepted the terms. (e.g. true)
]: any -> record<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record<id: string, type: string>, type: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({terms_of_service_user_status_id: $terms_of_service_user_status_id} | format pattern "/terms_of_service_user_statuses/{terms_of_service_user_status_id}"))
  let body = {"is_accepted": $is_accepted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List terms of services
#
# GET /terms_of_services
# operationId: get_terms_of_services
export def "terms-of-services services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tos-type: string@tos-type-completer # Limits the results to the terms of service of the given type. (e.g. managed)
]: nothing -> record<entries: list<record>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tos_type" $tos_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/terms_of_services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create terms of service
#
# POST /terms_of_services
# operationId: post_terms_of_services
export def "terms-of-services services-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-6 # Whether this terms of service is active. (e.g. enabled)
  text: string # The terms of service text to display to users.  The text can be set to empty if the `status` is set to `disabled`. (e.g. By collaborating on this file you are accepting...)
  --tos-type: string@tos-type-completer # The type of user to set the terms of service for. (e.g. managed)
]: any -> record<action: string, completion_rule: string, created_at: string, created_by: record, due_at: string, id: string, is_completed: bool, item: record, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/terms_of_services")
  let body = {"status": $status, "text": $text, "tos_type": $tos_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get terms of service
#
# GET /terms_of_services/{terms_of_service_id}
# operationId: get_terms_of_services_id
export def "terms-of-services id-by-terms_of_service_id" [
  terms_of_service_id: string
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
  let full_url = (build-url $base ({terms_of_service_id: $terms_of_service_id} | format pattern "/terms_of_services/{terms_of_service_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update terms of service
#
# PUT /terms_of_services/{terms_of_service_id}
# operationId: put_terms_of_services_id
export def "terms-of-services id-by-terms_of_service_id-1" [
  terms_of_service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-6 # Whether this terms of service is active. (e.g. enabled)
  text: string # The terms of service text to display to users.  The text can be set to empty if the `status` is set to `disabled`. (e.g. By collaborating on this file you are accepting...)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({terms_of_service_id: $terms_of_service_id} | format pattern "/terms_of_services/{terms_of_service_id}"))
  let body = {"status": $status, "text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List enterprise users
#
# GET /users
# operationId: get_users
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-term: string # Limits the results to only users who's `name` or `login` start with the search term.  For externally managed users, the search term needs to completely match the in order to find the user, and it will only return one user at a time. (e.g. john)
  --user-type: string@user-type-completer # Limits the results to the kind of user specified.  * `all` returns every kind of user for whom the   `login` or `name` partially matches the   `filter_term`. It will only return an external user   if the login matches the `filter_term` completely,   and in that case it will only return that user. * `managed` returns all managed and app users for whom   the `login` or `name` partially matches the   `filter_term`. * `external` returns all external users for whom the   `login` matches the `filter_term` exactly. (e.g. managed)
  --external-app-user-id: string # Limits the results to app users with the given `external_app_user_id` value.  When creating an app user, an `external_app_user_id` value can be set. This value can then be used in this endpoint to find any users that match that `external_app_user_id` value. (e.g. my-user-1234)
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --usemarker: oneof<nothing, bool> # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time.  By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_term" $filter_term "scalar") (serialize-qp "user_type" $user_type "scalar") (serialize-qp "external_app_user_id" $external_app_user_id "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "usemarker" $usemarker "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create user
#
# POST /users
# operationId: post_users
# --tracking_codes item shape: {name?: string, type?: "tracking_code", value?: string}
export def "users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --address: string # The user’s address (e.g. 900 Jefferson Ave, Redwood City, CA 94063)
  --can-see-managed-users: oneof<nothing, bool> # Whether the user can see other enterprise users in their contact list (e.g. true)
  --external-app-user-id: string # An external identifier for an app user, which can be used to look up the user. This can be used to tie user IDs from external identity providers to Box users. (e.g. my-user-1234)
  --is-exempt-from-device-limits: oneof<nothing, bool> # Whether to exempt the user from enterprise device limits (e.g. true)
  --is-exempt-from-login-verification: oneof<nothing, bool> # Whether the user must use two-factor authentication (e.g. true)
  --is-external-collab-restricted: oneof<nothing, bool> # Whether the user is allowed to collaborate with users outside their enterprise (e.g. true)
  --is-platform-access-only: oneof<nothing, bool> # Specifies that the user is an app user. (e.g. true)
  --is-sync-enabled: oneof<nothing, bool> # Whether the user can use Box Sync (e.g. true)
  --job-title: string # The user’s job title (e.g. CEO)
  --language: string # The language of the user, formatted in modified version of the [ISO 639-1](/guides/api-calls/language-codes) format. (e.g. en)
  --login: string # The email address the user uses to log in  Required, unless `is_platform_access_only` is set to `true`. (e.g. boss@box.com)
  name: string # The name of the user (e.g. Aaron Levie)
  --phone: string # The user’s phone number (e.g. 6509241374)
  --role: string@role-completer-3 # The user’s enterprise role (e.g. user)
  --space-amount: int # The user’s total available space in bytes. Set this to `-1` to indicate unlimited storage. (format: int64, e.g. 11345156112)
  --status: string@status-completer-7 # The user's account status (e.g. active)
  --timezone: string # The user's timezone (format: timezone, e.g. Africa/Bujumbura)
  --tracking-codes: list # Tracking codes allow an admin to generate reports from the admin console and assign an attribute to a specific group of users. This setting must be enabled for an enterprise before it can be used. — item shape: {name?: string, type?: "tracking_code", value?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let body = {"address": $address, "can_see_managed_users": $can_see_managed_users, "external_app_user_id": $external_app_user_id, "is_exempt_from_device_limits": $is_exempt_from_device_limits, "is_exempt_from_login_verification": $is_exempt_from_login_verification, "is_external_collab_restricted": $is_external_collab_restricted, "is_platform_access_only": $is_platform_access_only, "is_sync_enabled": $is_sync_enabled, "job_title": $job_title, "language": $language, "login": $login, "name": $name, "phone": $phone, "role": $role, "space_amount": $space_amount, "status": $status, "timezone": $timezone, "tracking_codes": $tracking_codes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get current user
#
# GET /users/me
# operationId: get_users_me
export def "users-me me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create jobs to terminate users session
#
# POST /users/terminate_sessions
# operationId: post_users_terminate_sessions
export def "users-terminate-sessions sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list # A list of user IDs (e.g. [123456, 456789])
  user_logins: list # A list of user logins (e.g. [user@sample.com, user2@sample.com])
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/terminate_sessions")
  let body = {"user_ids": $user_ids, "user_logins": $user_logins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete user
#
# DELETE /users/{user_id}
# operationId: delete_users_id
export def "users id-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Whether the user will receive email notification of the deletion (e.g. true)
  --force: oneof<nothing, bool> # Whether the user should be deleted even if this user still own files (e.g. true)
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user
#
# GET /users/{user_id}
# operationId: get_users_id
export def "users id-by-user_id-1" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /users/{user_id}
# operationId: put_users_id
# --notification_email shape: {email?: string}
# --tracking_codes item shape: {name?: string, type?: "tracking_code", value?: string}
export def "users id-by-user_id-2" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --address: string # The user’s address (e.g. 900 Jefferson Ave, Redwood City, CA 94063)
  --can-see-managed-users: oneof<nothing, bool> # Whether the user can see other enterprise users in their contact list (e.g. true)
  --enterprise: string # Set this to `null` to roll the user out of the enterprise and make them a free user (nullable)
  --external-app-user-id: string # An external identifier for an app user, which can be used to look up the user. This can be used to tie user IDs from external identity providers to Box users.  Note: In order to update this field, you need to request a token using the application that created the app user. (e.g. my-user-1234)
  --is-exempt-from-device-limits: oneof<nothing, bool> # Whether to exempt the user from enterprise device limits (e.g. true)
  --is-exempt-from-login-verification: oneof<nothing, bool> # Whether the user must use two-factor authentication (e.g. true)
  --is-external-collab-restricted: oneof<nothing, bool> # Whether the user is allowed to collaborate with users outside their enterprise (e.g. true)
  --is-password-reset-required: oneof<nothing, bool> # Whether the user is required to reset their password (e.g. true)
  --is-sync-enabled: oneof<nothing, bool> # Whether the user can use Box Sync (e.g. true)
  --job-title: string # The user’s job title (e.g. CEO)
  --language: string # The language of the user, formatted in modified version of the [ISO 639-1](/guides/api-calls/language-codes) format. (e.g. en)
  --login: string # The email address the user uses to log in  Note: If the target user's email is not confirmed, then the primary login address cannot be changed. (e.g. somename@box.com)
  --name: string # The name of the user (e.g. Aaron Levie)
  --notification-email: record # An alternate notification email address to which email notifications are sent. When it's confirmed, this will be the email address to which notifications are sent instead of to the primary email address.  Set this value to `null` to remove the notification email. (nullable) — shape: {email?: string}
  --notify: oneof<nothing, bool> # Whether the user should receive an email when they are rolled out of an enterprise (e.g. true)
  --phone: string # The user’s phone number (e.g. 6509241374)
  --role: string@role-completer-3 # The user’s enterprise role (e.g. user)
  --space-amount: int # The user’s total available space in bytes. Set this to `-1` to indicate unlimited storage. (format: int64, e.g. 11345156112)
  --status: string@status-completer-7 # The user's account status (e.g. active)
  --timezone: string # The user's timezone (format: timezone, e.g. Africa/Bujumbura)
  --tracking-codes: list # Tracking codes allow an admin to generate reports from the admin console and assign an attribute to a specific group of users. This setting must be enabled for an enterprise before it can be used. — item shape: {name?: string, type?: "tracking_code", value?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}") $qp)
  let body = {"address": $address, "can_see_managed_users": $can_see_managed_users, "enterprise": $enterprise, "external_app_user_id": $external_app_user_id, "is_exempt_from_device_limits": $is_exempt_from_device_limits, "is_exempt_from_login_verification": $is_exempt_from_login_verification, "is_external_collab_restricted": $is_external_collab_restricted, "is_password_reset_required": $is_password_reset_required, "is_sync_enabled": $is_sync_enabled, "job_title": $job_title, "language": $language, "login": $login, "name": $name, "notification_email": $notification_email, "notify": $notify, "phone": $phone, "role": $role, "space_amount": $space_amount, "status": $status, "timezone": $timezone, "tracking_codes": $tracking_codes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete user avatar
#
# DELETE /users/{user_id}/avatar
# operationId: delete_users_id_avatar
export def "users-avatar avatar-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/avatar"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user avatar
#
# GET /users/{user_id}/avatar
# operationId: get_users_id_avatar
export def "users-avatar avatar-by-user_id-1" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/avatar"))
  let accept_val = ($accept | default "image/jpg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or update user avatar
#
# POST /users/{user_id}/avatar
# operationId: post_users_id_avatar
export def "users-avatar avatar-by-user_id-2" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  pic: string # The image file to be uploaded to Box. Accepted file extensions are `.jpg` or `.png`. The maximum file size is 1MB. (format: binary)
]: any -> record<pic_urls: record<large: string, preview: string, small: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/avatar"))
  let body = {"pic": $pic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List user's email aliases
#
# GET /users/{user_id}/email_aliases
# operationId: get_users_id_email_aliases
export def "users-email-aliases aliases-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entries: table<email: string, id: string, is_confirmed: bool, type: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/email_aliases"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create email alias
#
# POST /users/{user_id}/email_aliases
# operationId: post_users_id_email_aliases
export def "users-email-aliases aliases-by-user_id-1" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address to add to the account as an alias.  Note: The domain of the email alias needs to be registered  to your enterprise. See the [domain verification guide](   https://support.box.com/hc/en-us/articles/4408619650579-Domain-Verification   ) for steps to add a new domain. (e.g. alias@example.com)
]: any -> record<email: string, id: string, is_confirmed: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/email_aliases"))
  let body = {"email": $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove email alias
#
# DELETE /users/{user_id}/email_aliases/{email_alias_id}
# operationId: delete_users_id_email_aliases_id
export def "users-email-aliases id" [
  user_id: string
  email_alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id, email_alias_id: $email_alias_id} | format pattern "/users/{user_id}/email_aliases/{email_alias_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfer owned folders
#
# PUT /users/{user_id}/folders/0
# operationId: put_users_id_folders_0
# --owned_by shape: {id: string}
export def "users-folders-0 folders-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --notify: oneof<nothing, bool> # Determines if users should receive email notification for the action performed. (e.g. true)
  owned_by: record # The user who the folder will be transferred to — shape: {id: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/folders/0") $qp)
  let body = {"owned_by": $owned_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List user's groups
#
# GET /users/{user_id}/memberships
# operationId: get_users_id_memberships
export def "users-memberships memberships" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}/memberships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create web link
#
# POST /web_links
# operationId: post_web_links
# --parent shape: {id: string}
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, unshared_at?: string, vanity_name?: string}
export def "web-links links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the web link. (e.g. Cloud Content Management)
  --name: string # Name of the web link. Defaults to the URL if not set. (e.g. Box Website)
  parent: record # The parent folder to create the web link within. — shape: {id: string}
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, unshared_at?: string, vanity_name?: string}
  --body-url: string # The URL that this web link links to. Must start with `"http://"` or `"https://"`. (e.g. https://box.com)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/web_links")
  let body = {"description": $description, "name": $name, "parent": $parent, "shared_link": $shared_link, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove web link
#
# DELETE /web_links/{web_link_id}
# operationId: delete_web_links_id
export def "web-links id-by-web_link_id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get web link
#
# GET /web_links/{web_link_id}
# operationId: get_web_links_id
export def "web-links id-by-web_link_id-1" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}"))
  let extra_headers = {"boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore web link
#
# POST /web_links/{web_link_id}
# operationId: post_web_links_id
export def "web-links id-by-web_link_id-2" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the web link. (e.g. Restored.docx)
  --parent: any
]: any -> record<created_at: string, created_by: record, description: string, etag: string, id: string, item_status: string, modified_at: string, modified_by: record, name: string, owned_by: record, parent: record, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: record, shared_link: string, trashed_at: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}") $qp)
  let body = {"name": $name, "parent": $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update web link
#
# PUT /web_links/{web_link_id}
# operationId: put_web_links_id
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, unshared_at?: string, vanity_name?: string}
export def "web-links id-by-web_link_id-3" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A new description of the web link. (e.g. Cloud Content Management)
  --name: string # A new name for the web link. Defaults to the URL if not set. (e.g. Box Website)
  --parent: any
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, unshared_at?: string, vanity_name?: string}
  --body-url: string # The new URL that the web link links to. Must start with `"http://"` or `"https://"`. (e.g. https://box.com)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}"))
  let body = {"description": $description, "name": $name, "parent": $parent, "shared_link": $shared_link, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add shared link to web link
#
# PUT /web_links/{web_link_id}#add_shared_link
# operationId: put_web_links_id#add_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
export def "web-links link-by-web_link_id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the web link.  Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}#add_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get shared link for web link
#
# GET /web_links/{web_link_id}#get_shared_link
# operationId: get_web_links_id#get_shared_link
export def "web-links link-by-web_link_id-1" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}#get_shared_link") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove shared link from web link
#
# PUT /web_links/{web_link_id}#remove_shared_link
# operationId: put_web_links_id#remove_shared_link
export def "web-links link-by-web_link_id-2" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the web link. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}#remove_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update shared link on web link
#
# PUT /web_links/{web_link_id}#update_shared_link
# operationId: put_web_links_id#update_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
export def "web-links link-by-web_link_id-3" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}#update_shared_link") $qp)
  let body = {"shared_link": $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Permanently remove web link
#
# DELETE /web_links/{web_link_id}/trash
# operationId: delete_web_links_id_trash
export def "web-links-trash trash-by-web_link_id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}/trash"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trashed web link
#
# GET /web_links/{web_link_id}/trash
# operationId: get_web_links_id_trash
export def "web-links-trash trash-by-web_link_id-1" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<created_at: string, created_by: record, description: string, etag: string, id: string, item_status: string, modified_at: string, modified_by: record, name: string, owned_by: record, parent: record, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: record, shared_link: string, trashed_at: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({web_link_id: $web_link_id} | format pattern "/web_links/{web_link_id}/trash") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all webhooks
#
# GET /webhooks
# operationId: get_webhooks
export def "webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /webhooks
# operationId: post_webhooks
# --target shape: {id?: string, type?: "file"|"folder"}
export def "webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The URL that is notified by this webhook (e.g. https://example.com/webhooks)
  target: record # The item that will trigger the webhook — shape: {id?: string, type?: "file"|"folder"}
  triggers: list # An array of event names that this webhook is to be triggered for (e.g. [FILE.UPLOADED])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {"address": $address, "target": $target, "triggers": $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove webhook
#
# DELETE /webhooks/{webhook_id}
# operationId: delete_webhooks_id
export def "webhooks id-by-webhook_id" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook
#
# GET /webhooks/{webhook_id}
# operationId: get_webhooks_id
export def "webhooks id-by-webhook_id-1" [
  webhook_id: string
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
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /webhooks/{webhook_id}
# operationId: put_webhooks_id
# --target shape: {id?: string, type?: "file"|"folder"}
export def "webhooks id-by-webhook_id-2" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The URL that is notified by this webhook (e.g. https://example.com/webhooks)
  --target: record # The item that will trigger the webhook — shape: {id?: string, type?: "file"|"folder"}
  --triggers: list # An array of event names that this webhook is to be triggered for (e.g. [FILE.UPLOADED])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/webhooks/{webhook_id}"))
  let body = {"address": $address, "target": $target, "triggers": $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List workflows
#
# GET /workflows
# operationId: get_workflows
export def "workflows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --folder-id: string # The unique identifier that represent a folder.  The ID for any folder can be determined by visiting this folder in the web application and copying the ID from the URL. For example, for the URL `https://*.app.box.com/folder/123` the `folder_id` is `123`.  The root folder of a Box account is always represented by the ID `0`. (e.g. 12345)
  --trigger-type: string # Type of trigger to search for. (e.g. WORKFLOW_MANUAL_START)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folder_id" $folder_id "scalar") (serialize-qp "trigger_type" $trigger_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts workflow based on request body
#
# POST /workflows/{workflow_id}/start
# operationId: post_workflows_id_start
# --files item shape: {id?: string, type?: "file"}
# --flow shape: {id?: string, type?: string}
# --folder shape: {id?: string, type?: "folder"}
# --outcomes item shape: {id?: string, parameter?: string, type?: "outcome"}
export def "workflows-start start" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  files: list # The array of files for which the workflow should start. All files must be in the workflow's configured folder. — item shape: {id?: string, type?: "file"}
  flow: record # The flow that will be triggered — shape: {id?: string, type?: string}
  folder: record # The folder object for which the workflow is configured. — shape: {id?: string, type?: "folder"}
  --outcomes: list # A list of outcomes required to be configured at start time. — item shape: {id?: string, parameter?: string, type?: "outcome"}
  --type: string@type-completer-6 # The type of the parameters object (e.g. workflow_parameters)
]: any -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}/start"))
  let body = {"files": $files, "flow": $flow, "folder": $folder, "outcomes": $outcomes, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create zip download
#
# POST /zip_downloads
# operationId: post_zip_downloads
# --items item shape: {id: string, type: "file"|"folder."}
export def "zip-downloads download-s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --download-file-name: string # The optional name of the `zip` archive. This name will be appended by the `.zip` file extension, for example `January Financials.zip`. (e.g. January Financials)
  items: list # A list of items to add to the `zip` archive. These can be folders or files. — item shape: {id: string, type: "file"|"folder."}
]: any -> record<download_url: string, expires_at: string, name_conflicts: list<list<record>>, status_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/zip_downloads")
  let body = {"download_file_name": $download_file_name, "items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download zip archive
#
# GET /zip_downloads/{zip_download_id}/content
# operationId: get_zip_downloads_id_content
export def "zip-downloads-content content" [
  zip_download_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<code: string, context_info: record<message: string>, help_url: string, message: string, request_id: string, status: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dl.boxcloud.com/2.0")
  let full_url = (build-url $base ({zip_download_id: $zip_download_id} | format pattern "/zip_downloads/{zip_download_id}/content"))
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get zip download status
#
# GET /zip_downloads/{zip_download_id}/status
# operationId: get_zip_downloads_id_status
export def "zip-downloads-status status" [
  zip_download_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<downloaded_file_count: int, skipped_file_count: int, skipped_folder_count: int, state: string, total_file_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({zip_download_id: $zip_download_id} | format pattern "/zip_downloads/{zip_download_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
