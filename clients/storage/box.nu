# Auto-generated client for Box Platform API v2024.0
# Source: https://raw.githubusercontent.com/box/box-openapi/main/openapi.json
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
def base-url-completer [] { ["https://api.box.com/2.0" "https://account.box.com/api/oauth2" "https://api.box.com" "https://upload.box.com/api/2.0" "https://dl.boxcloud.com/2.0" "https://{box-upload-server}/api/2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def response-type-completer [] { ["code"] }
def grant-type-completer [] { ["authorization_code" "client_credentials" "refresh_token" "urn:ietf:params:oauth:grant-type:jwt-bearer" "urn:ietf:params:oauth:grant-type:token-exchange"] }
def subject-token-type-completer [] { ["urn:ietf:params:oauth:token-type:access_token"] }
def actor-token-type-completer [] { ["urn:ietf:params:oauth:token-type:id_token"] }
def box-subject-type-completer [] { ["enterprise" "user"] }
def grant-type-completer-1 [] { ["refresh_token"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def accept-completer-1 [] { ["application/json" "image/jpg" "image/png"] }
def type-completer [] { ["file_version"] }
def status-completer [] { ["active" "inactive"] }
def sort-completer [] { ["date" "id" "name" "size"] }
def direction-completer [] { ["ASC" "DESC"] }
def sync-state-completer [] { ["not_synced" "partially_synced" "synced"] }
def sort-completer-1 [] { ["date" "name" "size"] }
def scope-completer [] { ["enterprise"] }
def templateKey-completer [] { ["securityClassification-6VMVochwUWo"] }
def displayName-completer [] { ["Classification"] }
def scope-completer-1 [] { ["enterprise" "global"] }
def conflict-resolution-completer [] { ["none" "overwrite"] }
def role-completer [] { ["co-owner" "editor" "owner" "previewer" "previewer uploader" "uploader" "viewer" "viewer uploader"] }
def status-completer-1 [] { ["accepted" "pending" "rejected"] }
def status-completer-2 [] { ["pending"] }
def role-completer-1 [] { ["co-owner" "editor" "previewer" "previewer uploader" "uploader" "viewer" "viewer uploader"] }
def scope-completer-2 [] { ["enterprise_content" "user_content"] }
def type-completer-1 [] { ["file" "folder" "web_link"] }
def trash-content-completer [] { ["all_items" "non_trashed_only" "trashed_only"] }
def sort-completer-2 [] { ["modified_at" "relevance"] }
def action-completer [] { ["complete" "review"] }
def completion-rule-completer [] { ["all_assignees" "any_assignee"] }
def resolution-state-completer [] { ["approved" "completed" "incomplete" "rejected"] }
def user-type-completer [] { ["all" "external" "managed"] }
def role-completer-2 [] { ["coadmin" "user"] }
def status-completer-3 [] { ["active" "cannot_delete_edit" "cannot_delete_edit_upload" "inactive"] }
def accept-completer-2 [] { ["application/json" "image/jpg"] }
def invitability-level-completer [] { ["admins_and_members" "admins_only" "all_managed_users"] }
def member-viewability-level-completer [] { ["admins_and_members" "admins_only" "all_managed_users"] }
def role-completer-3 [] { ["admin" "member"] }
def status-completer-4 [] { ["invoked" "permanent_failure" "processing" "success" "transient_failure"] }
def stream-type-completer [] { ["admin_logs" "admin_logs_streaming" "all" "changes" "sync"] }
def policy-type-completer [] { ["finite" "indefinite"] }
def disposition-action-completer [] { ["permanently_delete" "remove_retention"] }
def retention-type-completer [] { ["modifiable" "non_modifiable"] }
def type-completer-2 [] { ["enterprise" "folder" "metadata_template"] }
def assign-to-type-completer [] { ["file" "file_version" "folder" "interactions" "ownership" "user"] }
def status-completer-5 [] { ["disabled" "pending"] }
def type-completer-3 [] { ["shield_information_barrier_segment_member"] }
def type-completer-4 [] { ["shield_information_barrier_segment_restriction"] }
def tos-type-completer [] { ["external" "managed"] }
def status-completer-6 [] { ["disabled" "enabled"] }
def direction-completer-1 [] { ["both" "inbound" "outbound"] }
def resolved-for-type-completer [] { ["enterprise" "user"] }
def signature-color-completer [] { ["black" "blue" "red"] }
def type-completer-5 [] { ["workflow_parameters"] }
def partner-item-type-completer [] { ["channel"] }
def box-item-type-completer [] { ["folder"] }
def partner-item-type-completer-1 [] { ["channel" "team"] }
def mode-completer [] { ["multiple_item_qa" "single_item_qa"] }
def mode-completer-1 [] { ["ask" "extract" "extract_structured" "text_gen"] }
def type-completer-6 [] { ["ai_agent"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authorize authorize" } } | get name | first)
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
export def "authorize authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --response-type: string@response-type-completer # The type of response we'd like to receive. (format: token, e.g. code)
  --client-id: string # The Client ID of the application that is requesting to authenticate the user. To get the Client ID for your application, log in to your Box developer console and click the **Edit Application** link for the application you're working with. In the OAuth 2.0 Parameters section of the configuration page, find the item labelled `client_id`. The text of that item is your application's Client ID. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --redirect-uri: string # The URI to which Box redirects the browser after the user has granted or denied the application permission. This URI match one of the redirect URIs in the configuration of your application. It must be a valid HTTPS URI and it needs to be able to handle the redirection to complete the next step in the OAuth 2.0 flow. Although this parameter is optional, it must be a part of the authorization URL if you configured multiple redirect URIs for the application in the developer console. A missing parameter causes a `redirect_uri_missing` error after the user grants application access. (format: url, e.g. http://example.com/auth/callback)
  --state: string # A custom string of your choice. Box will pass the same string to the redirect URL when authentication is complete. This parameter can be used to identify a user on redirect, as well as protect against hijacked sessions and other exploits. (e.g. my_state)
  --scope: string # A space-separated list of application scopes you'd like to authenticate the user for. This defaults to all the scopes configured for the application in its configuration page. (e.g. admin_readwrite)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://account.box.com/api/oauth2")
  let qp = [(serialize-qp "response_type" $response_type "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorize" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  grant_type: string@grant-type-completer # The type of request being made, either using a client-side obtained authorization code, a refresh token, a JWT assertion, client credentials grant or another access token for the purpose of downscoping a token. (format: urn, e.g. authorization_code)
  --client-id: string # The Client ID of the application requesting an access token.  Used in combination with `authorization_code`, `client_credentials`, or `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --client-secret: string # The client secret of the application requesting an access token.  Used in combination with `authorization_code`, `client_credentials`, or `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  --code: string # The client-side authorization code passed to your application by Box in the browser redirect after the user has successfully granted your application permission to make API calls on their behalf.  Used in combination with `authorization_code` as the `grant_type`. (format: token, e.g. n22JPxrh18m4Y0wIZPIqYZK7VRrsMTWW)
  --refresh-token: string # A refresh token used to get a new access token with.  Used in combination with `refresh_token` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --assertion: string # A JWT assertion for which to request a new access token.  Used in combination with `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (format: jwt, e.g. xxxxx.yyyyy.zzzzz)
  --subject-token: string # The token to exchange for a downscoped token. This can be a regular access token, a JWT assertion, or an app token.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --subject-token-type: string@subject-token-type-completer # The type of `subject_token` passed in.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (e.g. urn:ietf:params:oauth:token-type:access_token)
  --actor-token: string # The token used to create an annotator token. This is a JWT assertion.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --actor-token-type: string@actor-token-type-completer # The type of `actor_token` passed in.  Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: urn, e.g. urn:ietf:params:oauth:token-type:id_token)
  --scope: string # The space-delimited list of scopes that you want apply to the new access token.  The `subject_token` will need to have all of these scopes or the call will error with **401 Unauthorized**.. (format: space_delimited_list, e.g. item_upload item_preview base_explorer)
  --resource: string # Full URL for the file that the token should be generated for. (format: url, e.g. https://api.box.com/2.0/files/123456)
  --box-subject-type: string@box-subject-type-completer # Used in combination with `client_credentials` as the `grant_type`. (e.g. enterprise)
  --box-subject-id: string # Used in combination with `client_credentials` as the `grant_type`. Value is determined by `box_subject_type`. If `user` use user ID and if `enterprise` use enterprise ID. (e.g. 123456789)
  --box-shared-link: string # Full URL of the shared link on the file or folder that the token should be generated for. (format: url, e.g. https://cloud.box.com/s/123456)
]: any -> record<access_token: string, expires_in: int, token_type: string, restricted_to: table<scope: string, object: record>, refresh_token: string, issued_token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.box.com")
  let full_url = (build-url $base "/oauth2/token")
  let body = {grant_type: $grant_type, client_id: $client_id, client_secret: $client_secret, code: $code, refresh_token: $refresh_token, assertion: $assertion, subject_token: $subject_token, subject_token_type: $subject_token_type, actor_token: $actor_token, actor_token_type: $actor_token_type, scope: $scope, resource: $resource, box_subject_type: $box_subject_type, box_subject_id: $box_subject_id, box_shared_link: $box_shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
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
  grant_type: string@grant-type-completer-1 # The type of request being made, in this case a refresh request. (format: urn, e.g. refresh_token)
  client_id: string # The client ID of the application requesting to refresh the token. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  client_secret: string # The client secret of the application requesting to refresh the token. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  refresh_token: string # The refresh token to refresh. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
]: any -> record<access_token: string, expires_in: int, token_type: string, restricted_to: table<scope: string, object: record>, refresh_token: string, issued_token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.box.com")
  let full_url = (build-url $base "/oauth2/token#refresh")
  let body = {grant_type: $grant_type, client_id: $client_id, client_secret: $client_secret, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
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
  --client-id: string # The Client ID of the application requesting to revoke the access token. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --client-secret: string # The client secret of the application requesting to revoke an access token. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  --body-token: string # The access token to revoke. (format: token, e.g. n22JPxrh18m4Y0wIZPIqYZK7VRrsMTWW)
]: any -> record<error: string, error_description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.box.com")
  let full_url = (build-url $base "/oauth2/revoke")
  let body = {client_id: $client_id, client_secret: $client_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get file information
#
# GET /files/{file_id}
# operationId: get_files_id
export def "files id-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested.  Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?fields=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
  --x-rep-hints: string # A header required to request specific `representations` of a file. Use this in combination with the `fields` query parameter to request a specific file representation.  The general format for these representations is `X-Rep-Hints: [...]` where `[...]` is one or many hints in the format `[fileType?query]`.  For example, to request a `png` representation in `32x32` as well as `64x64` pixel dimensions provide the following hints.  `x-rep-hints: [jpg?dimensions=32x32][jpg?dimensions=64x64]`  Additionally, a `text` representation is available for all document file types in Box using the `[extracted_text]` representation.  `x-rep-hints: [extracted_text]`. (e.g. [pdf])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi, "x-rep-hints": $x_rep_hints} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore file
#
# POST /files/{file_id}
# operationId: post_files_id
export def "files id-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the file. (e.g. Restored.docx)
  --parent: any
]: any -> record<id: string, etag: string, type: string, sequence_id: record, name: string, sha1: string, file_version: record, description: string, size: int, path_collection: record<total_count: int, entries: list<record>>, created_at: string, modified_at: string, trashed_at: string, purged_at: string, content_created_at: string, content_modified_at: string, created_by: record, modified_by: record, owned_by: record, shared_link: string, parent: record, item_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)" $qp)
  let body = {name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update file
#
# PUT /files/{file_id}
# operationId: put_files_id
# --lock shape: {access?: "lock", expires_at?: string, is_download_prevented?: bool}
# --permissions shape: {can_download?: "open"|"company"}
# --collections item shape: {id?: string, type?: string}
export def "files id-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --name: string # An optional different name for the file. This can be used to rename the file.  File names must be unique within their parent folder. The name check is case-insensitive, so a file named `New File` cannot be created in a parent folder that already contains a folder named `new file`. (e.g. NewFile.txt)
  --description: string # The description for a file. This can be seen in the right-hand sidebar panel when viewing a file in the Box web app. Additionally, this index is used in the search index of the file, allowing users to find the file by the content in the description. (e.g. The latest reports. Automatically updated)
  --parent: any
  --shared-link: any # nullable
  --lock: record # Defines a lock on an item. This prevents the item from being moved, renamed, or otherwise changed by anyone other than the user who created the lock.  Set this to `null` to remove the lock. (nullable) — shape: {access?: "lock", expires_at?: string, is_download_prevented?: bool}
  --disposition-at: string # The retention expiration timestamp for the given file. This date cannot be shortened once set on a file. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --permissions: record # Defines who can download a file. — shape: {can_download?: "open"|"company"}
  --collections: list # An array of collections to make this file a member of. Currently we only support the `favorites` collection.  To get the ID for a collection, use the [List all collections][1] endpoint.  Passing an empty array `[]` or `null` will remove the file from all collections.  [1]: https://developer.box.com/reference/get-collections (nullable) — item shape: {id?: string, type?: string}
  --tags: list # The tags for this item. These tags are shown in the Box web app and mobile apps next to an item.  To add or remove a tag, retrieve the item's current tags, modify them, and then update this field.  There is a limit of 100 tags per item, and 10,000 unique tags per enterprise. (e.g. [approved])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)" $qp)
  let body = {name: $name, description: $description, parent: $parent, shared_link: $shared_link, lock: $lock, disposition_at: $disposition_at, permissions: $permissions, collections: $collections, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete file
#
# DELETE /files/{file_id}
# operationId: delete_files_id
export def "files id-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)")
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List file app item associations
#
# GET /files/{file_id}/app_item_associations
# operationId: get_files_id_app_item_associations
export def "files-app-item-associations associations" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --application-type: string # If given, only return app items for this application type. (e.g. hubs)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "application_type" $application_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/app_item_associations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --version: string # The file version to download. (e.g. 4)
  --access-token: string # An optional access token that can be used to pre-authenticate this request, which means that a download link can be shared with a browser or a third party service without them needing to know how to handle the authentication. When using this parameter, please make sure that the access token is sufficiently scoped down to only allow read access to that file and no other files or folders. (e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --range: string # The byte range of the content to download.  The format `bytes={start_byte}-{end_byte}` can be used to specify what section of the file to download. (e.g. bytes=0-1024)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "access_token" $access_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/content" $qp)
  let extra_headers = {"range": $range, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload file version
#
# POST /files/{file_id}/content
# operationId: post_files_id_content
# --attributes shape: {name: string, content_modified_at?: string}
export def "files-content content-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --content-md5: string # An optional header containing the SHA1 hash of the file to ensure that the file was not corrupted in transit. (e.g. 134b65991ed521fcfe4724b7d814ab8ded5185dc)
  attributes: record # The additional attributes of the file being uploaded. Mainly the name and the parent folder. These attributes are part of the multi part request body and are in JSON format.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> — shape: {name: string, content_modified_at?: string}
  file: string # The content of the file to upload to Box.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> (format: binary)
]: any -> record<total_count: int, entries: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/content" $qp)
  let body = {attributes: $attributes, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match, "content-md5": $content_md5} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
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
  --name: string # The name for the file. (e.g. File.mp4)
  --size: int # The size of the file in bytes. (format: int32, e.g. 1024)
  --parent: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/content")
  let body = {name: $name, size: $size, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload file
#
# POST /files/content
# operationId: post_files_content
# --attributes shape: {name: string, parent: record, content_created_at?: string, content_modified_at?: string}
export def "files-content content-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --content-md5: string # An optional header containing the SHA1 hash of the file to ensure that the file was not corrupted in transit. (e.g. 134b65991ed521fcfe4724b7d814ab8ded5185dc)
  attributes: record # The additional attributes of the file being uploaded. Mainly the name and the parent folder. These attributes are part of the multi part request body and are in JSON format.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> — shape: {name: string, parent: record, content_created_at?: string, content_modified_at?: string}
  file: string # The content of the file to upload to Box.  <Message warning>    The `attributes` part of the body must come **before** the   `file` part. Requests that do not follow this format when   uploading the file will receive a HTTP `400` error with a   `metadata_after_file_contents` error code.  </Message> (format: binary)
]: any -> record<total_count: int, entries: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/files/content" $qp)
  let body = {attributes: $attributes, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"content-md5": $content_md5} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
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
  folder_id: string # The ID of the folder to upload the new file to. (e.g. 0)
  file_size: int # The total number of bytes of the file to be uploaded. (format: int64, e.g. 104857600)
  file_name: string # The name of new file. (e.g. Project.mov)
]: any -> record<id: string, type: string, session_expires_at: string, part_size: int, total_parts: int, num_parts_processed: int, session_endpoints: record<upload_part: string, commit: string, abort: string, list_parts: string, status: string, log_event: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base "/files/upload_sessions")
  let body = {folder_id: $folder_id, file_size: $file_size, file_name: $file_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  file_size: int # The total number of bytes of the file to be uploaded. (format: int64, e.g. 104857600)
  --file-name: string # The optional new name of new file. (e.g. Project.mov)
]: any -> record<id: string, type: string, session_expires_at: string, part_size: int, total_parts: int, num_parts_processed: int, session_endpoints: record<upload_part: string, commit: string, abort: string, list_parts: string, status: string, log_event: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://upload.box.com/api/2.0")
  let full_url = (build-url $base $"/files/($file_id)/upload_sessions")
  let body = {file_size: $file_size, file_name: $file_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get upload session
#
# GET /files/upload_sessions/{upload_session_id}
# operationId: get_files_upload_sessions_id
export def "files-upload-sessions id-by-upload_session_id" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, session_expires_at: string, part_size: int, total_parts: int, num_parts_processed: int, session_endpoints: record<upload_part: string, commit: string, abort: string, list_parts: string, status: string, log_event: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{box-upload-server}/api/2.0")
  let full_url = (build-url $base $"/files/upload_sessions/($upload_session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload part of file
#
# PUT /files/upload_sessions/{upload_session_id}
# operationId: put_files_upload_sessions_id
export def "files-upload-sessions id-by-upload_session_id-1" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --digest: string # The [RFC3230][1] message digest of the chunk uploaded.  Only SHA1 is supported. The SHA1 digest must be base64 encoded. The format of this header is as `sha=BASE64_ENCODED_DIGEST`.  To get the value for the `SHA` digest, use the openSSL command to encode the file part: `openssl sha1 -binary <FILE_PART_NAME> | base64`.  [1]: https://tools.ietf.org/html/rfc3230 (e.g. sha=fpRyg5eVQletdZqEKaFlqwBXJzM=)
  --content-range: string # The byte range of the chunk.  Must not overlap with the range of a part already uploaded this session. Each part’s size must be exactly equal in size to the part size specified in the upload session that you created. One exception is the last part of the file, as this can be smaller.  When providing the value for `content-range`, remember that:  * The lower bound of each part's byte range   must be a multiple of the part size. * The higher bound must be a multiple of the part size - 1. (e.g. bytes 8388608-16777215/445856194)
  --body: record
]: any -> record<part: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{box-upload-server}/api/2.0")
  let full_url = (build-url $base $"/files/upload_sessions/($upload_session_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"digest": $digest, "content-range": $content_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Remove upload session
#
# DELETE /files/upload_sessions/{upload_session_id}
# operationId: delete_files_upload_sessions_id
export def "files-upload-sessions id-by-upload_session_id-2" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{box-upload-server}/api/2.0")
  let full_url = (build-url $base $"/files/upload_sessions/($upload_session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{box-upload-server}/api/2.0")
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/upload_sessions/($upload_session_id)/parts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit upload session
#
# POST /files/upload_sessions/{upload_session_id}/commit
# operationId: post_files_upload_sessions_id_commit
# --parts item shape: {part_id?: string, offset?: int, size?: int, sha1?: string}
export def "files-upload-sessions-commit commit" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --digest: string # The [RFC3230][1] message digest of the whole file.  Only SHA1 is supported. The SHA1 digest must be Base64 encoded. The format of this header is as `sha=BASE64_ENCODED_DIGEST`.  [1]: https://tools.ietf.org/html/rfc3230 (e.g. sha=fpRyg5eVQletdZqEKaFlqwBXJzM=)
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  parts: list # The list details for the uploaded parts. — item shape: {part_id?: string, offset?: int, size?: int, sha1?: string}
]: any -> record<total_count: int, entries: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{box-upload-server}/api/2.0")
  let full_url = (build-url $base $"/files/upload_sessions/($upload_session_id)/commit")
  let body = {parts: $parts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"digest": $digest, "if-match": $if_match, "if-none-match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the copied file.  There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), and protected names like `.` and `..` are automatically sanitized by removing the non-allowed characters. (e.g. FileCopy.txt)
  --version: string # An optional ID of the specific file version to copy. (e.g. 0)
  parent: record # The destination folder to copy the file to. — shape: {id: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/copy" $qp)
  let body = {name: $name, version: $version, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer-1 # Response content type
  --min-height: int # The minimum height of the thumbnail. (e.g. 32)
  --min-width: int # The minimum width of the thumbnail. (e.g. 32)
  --max-height: int # The maximum height of the thumbnail. (e.g. 320)
  --max-width: int # The maximum width of the thumbnail. (e.g. 320)
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_height" $min_height "scalar") (serialize-qp "min_width" $min_width "scalar") (serialize-qp "max_height" $max_height "scalar") (serialize-qp "max_width" $max_width "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/thumbnail.($extension)" $qp)
  let accept_val = ($accept | default "image/jpg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/collaborations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<total_count: int, entries: table<id: string, type: string, item: record, due_at: string, action: string, message: string, task_assignment_collection: record, is_completed: bool, created_by: record, created_at: string, completion_rule: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trashed file
#
# GET /files/{file_id}/trash
# operationId: get_files_id_trash
export def "files-trash trash-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<id: string, etag: string, type: string, sequence_id: record, name: string, sha1: string, file_version: record, description: string, size: int, path_collection: record<total_count: int, entries: list<record>>, created_at: string, modified_at: string, trashed_at: string, purged_at: string, content_created_at: string, content_modified_at: string, created_by: record, modified_by: record, owned_by: record, shared_link: string, parent: record, item_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/trash" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently remove file
#
# DELETE /files/{file_id}/trash
# operationId: delete_files_id_trash
export def "files-trash trash-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/trash")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all file versions
#
# GET /files/{file_id}/versions
# operationId: get_files_id_versions
export def "files-versions versions" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file version
#
# GET /files/{file_id}/versions/{file_version_id}
# operationId: get_files_id_versions_id
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/versions/($file_version_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove file version
#
# DELETE /files/{file_id}/versions/{file_version_id}
# operationId: delete_files_id_versions_id
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
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/versions/($file_version_id)")
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --trashed-at: string # Set this to `null` to clear the date and restore the file. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/versions/($file_version_id)")
  let body = {trashed_at: $trashed_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --id: string # The file version ID. (e.g. 11446498)
  --type: string@type-completer # The type to promote. (e.g. file_version)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/versions/current" $qp)
  let body = {id: $id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --view: string # Taxonomy field values are returned in `API view` by default, meaning  the value is represented with a taxonomy node identifier.  To retrieve the `Hydrated view`, where taxonomy values are represented  with the full taxonomy node information, set this parameter to `hydrated`.  This is the only supported value for this parameter. (e.g. hydrated)
]: nothing -> record<entries: list<record>, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get classification on file
#
# GET /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: get_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Box__Security__Classification__Key: string, _parent: string, _template: string, _scope: string, _version: int, _type: string, _typeVersion: float, _canEdit: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add classification to file
#
# POST /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: post_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Box-Security--Classification--Key: string # The name of the classification to apply to this file.  To list the available classifications in an enterprise, use the classification API to retrieve the [classification template](https://developer.box.com/reference/get-metadata-templates-enterprise-securityClassification-6VMVochwUWo-schema) which lists all available classification keys. (e.g. Sensitive)
]: any -> record<Box__Security__Classification__Key: string, _parent: string, _template: string, _scope: string, _version: int, _type: string, _typeVersion: float, _canEdit: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let body = {Box__Security__Classification__Key: $Box_Security__Classification__Key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update classification on file
#
# PUT /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: put_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<Box__Security__Classification__Key: string, _parent: string, _template: string, _scope: string, _version: int, _type: string, _typeVersion: float, _canEdit: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json-patch+json" $body
}

# Remove classification from file
#
# DELETE /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: delete_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "files-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metadata instance on file
#
# GET /files/{file_id}/metadata/{scope}/{template_key}
# operationId: get_files_id_metadata_id_id
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
  --view: string # Taxonomy field values are returned in `API view` by default, meaning  the value is represented with a taxonomy node identifier.  To retrieve the `Hydrated view`, where taxonomy values are represented  with the full taxonomy node information, set this parameter to `hydrated`.  This is the only supported value for this parameter. (e.g. hydrated)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/metadata/($scope)/($template_key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create metadata instance on file
#
# POST /files/{file_id}/metadata/{scope}/{template_key}
# operationId: post_files_id_metadata_id_id
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
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/($scope)/($template_key)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update metadata instance on file
#
# PUT /files/{file_id}/metadata/{scope}/{template_key}
# operationId: put_files_id_metadata_id_id
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
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/($scope)/($template_key)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json-patch+json" $body
}

# Remove metadata instance from file
#
# DELETE /files/{file_id}/metadata/{scope}/{template_key}
# operationId: delete_files_id_metadata_id_id
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
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/($scope)/($template_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Box Skill cards on file
#
# GET /files/{file_id}/metadata/global/boxSkillsCards
# operationId: get_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_canEdit: bool, _id: string, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: int, _version: int, cards: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/global/boxSkillsCards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Box Skill cards on file
#
# POST /files/{file_id}/metadata/global/boxSkillsCards
# operationId: post_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cards: list # A list of Box Skill cards to apply to this file.
]: any -> record<_canEdit: bool, _id: string, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: int, _version: int, cards: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/global/boxSkillsCards")
  let body = {cards: $cards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Box Skill cards on file
#
# PUT /files/{file_id}/metadata/global/boxSkillsCards
# operationId: put_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<_canEdit: bool, _id: string, _parent: string, _scope: string, _template: string, _type: string, _typeVersion: int, _version: int, cards: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/global/boxSkillsCards")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json-patch+json" $body
}

# Remove Box Skill cards from file
#
# DELETE /files/{file_id}/metadata/global/boxSkillsCards
# operationId: delete_files_id_metadata_global_boxSkillsCards
export def "files-metadata-global-box-skills-cards boxSkillsCards-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/metadata/global/boxSkillsCards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get watermark on file
#
# GET /files/{file_id}/watermark
# operationId: get_files_id_watermark
export def "files-watermark watermark-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<watermark: record<created_at: string, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply watermark to file
#
# PUT /files/{file_id}/watermark
# operationId: put_files_id_watermark
# --watermark shape: {imprint: "default"}
export def "files-watermark watermark-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  watermark: record # The watermark to imprint on the file. — shape: {imprint: "default"}
]: any -> record<watermark: record<created_at: string, modified_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/watermark")
  let body = {watermark: $watermark} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove watermark from file
#
# DELETE /files/{file_id}/watermark
# operationId: delete_files_id_watermark
export def "files-watermark watermark-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file request
#
# GET /file_requests/{file_request_id}
# operationId: get_file_requests_id
export def "file-requests id-by-file_request_id" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, title: string, description: string, status: string, is_email_required: bool, is_description_required: bool, expires_at: string, folder: record, url: string, etag: string, created_by: record, created_at: string, updated_by: record, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file_requests/($file_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update file request
#
# PUT /file_requests/{file_request_id}
# operationId: put_file_requests_id
export def "file-requests id-by-file_request_id-1" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --title: string # An optional new title for the file request. This can be used to change the title of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
  --description: string # An optional new description for the file request. This can be used to change the description of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
  --status: string@status-completer # An optional new status of the file request.  When the status is set to `inactive`, the file request will no longer accept new submissions, and any visitor to the file request URL will receive a `HTTP 404` status code.  This will default to the value on the existing file request. (e.g. active)
  --is-email-required: string@bool-completer # Whether a file request submitter is required to provide their email address.  When this setting is set to true, the Box UI will show an email field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --is-description-required: string@bool-completer # Whether a file request submitter is required to provide a description of the files they are submitting.  When this setting is set to true, the Box UI will show a description field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --expires-at: string # The date after which a file request will no longer accept new submissions.  After this date, the `status` will automatically be set to `inactive`.  This will default to the value on the existing file request. (format: date-time, e.g. 2020-09-28T10:53:43-08:00)
]: any -> record<id: string, type: string, title: string, description: string, status: string, is_email_required: bool, is_description_required: bool, expires_at: string, folder: record, url: string, etag: string, created_by: record, created_at: string, updated_by: record, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file_requests/($file_request_id)")
  let body = {title: $title, description: $description, status: $status, is_email_required: $is_email_required, is_description_required: $is_description_required, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete file request
#
# DELETE /file_requests/{file_request_id}
# operationId: delete_file_requests_id
export def "file-requests id-by-file_request_id-2" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file_requests/($file_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy file request
#
# POST /file_requests/{file_request_id}/copy
# operationId: post_file_requests_id_copy
# --folder shape: {type?: "folder", id: string}
export def "file-requests-copy copy" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # An optional new title for the file request. This can be used to change the title of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
  --description: string # An optional new description for the file request. This can be used to change the description of the file request.  This will default to the value on the existing file request. (e.g. Please upload required documents)
  --status: string@status-completer # An optional new status of the file request.  When the status is set to `inactive`, the file request will no longer accept new submissions, and any visitor to the file request URL will receive a `HTTP 404` status code.  This will default to the value on the existing file request. (e.g. active)
  --is-email-required: string@bool-completer # Whether a file request submitter is required to provide their email address.  When this setting is set to true, the Box UI will show an email field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --is-description-required: string@bool-completer # Whether a file request submitter is required to provide a description of the files they are submitting.  When this setting is set to true, the Box UI will show a description field on the file request form.  This will default to the value on the existing file request. (e.g. true)
  --expires-at: string # The date after which a file request will no longer accept new submissions.  After this date, the `status` will automatically be set to `inactive`.  This will default to the value on the existing file request. (format: date-time, e.g. 2020-09-28T10:53:43-08:00)
  folder: record # The folder to associate the new file request to. — shape: {type?: "folder", id: string}
]: any -> record<id: string, type: string, title: string, description: string, status: string, is_email_required: bool, is_description_required: bool, expires_at: string, folder: record, url: string, etag: string, created_by: record, created_at: string, updated_by: record, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file_requests/($file_request_id)/copy")
  let body = {title: $title, description: $description, status: $status, is_email_required: $is_email_required, is_description_required: $is_description_required, expires_at: $expires_at, folder: $folder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get folder information
#
# GET /folders/{folder_id}
# operationId: get_folders_id
export def "folders id-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested.  Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?fields=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --qp-sort: string@sort-completer # Defines the **second** attribute by which items are sorted.  The folder type affects the way the items are sorted:    * **Standard folder**:   Items are always sorted by   their `type` first, with   folders listed before files,   and files listed   before web links.    * **Root folder**:   This parameter is not supported   for marker-based pagination   on the root folder    (the folder with an `id` of `0`).    * **Shared folder with parent path   to the associated folder visible to   the collaborator**:   Items are always sorted by   their `type` first, with   folders listed before files,   and files listed   before web links. (e.g. id)
  --direction: string@direction-completer # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
  --offset: int # The offset of the item at which to begin the response.  Offset-based pagination is not guaranteed to work reliably for high offset values and may fail for large datasets. In those cases, reduce the number of items in the folder (for example, by restructuring the folder into smaller subfolders) before retrying the request. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore folder
#
# POST /folders/{folder_id}
# operationId: post_folders_id
export def "folders id-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the folder. (e.g. Restored Photos)
  --parent: any
]: any -> record<id: string, etag: string, type: string, sequence_id: record, name: string, created_at: string, modified_at: string, description: record, size: int, path_collection: record<total_count: int, entries: list<record>>, created_by: record, modified_by: record, trashed_at: string, purged_at: string, content_created_at: string, content_modified_at: string, owned_by: record, shared_link: string, folder_upload_email: string, parent: record, item_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)" $qp)
  let body = {name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update folder
#
# PUT /folders/{folder_id}
# operationId: put_folders_id
# --collections item shape: {id?: string, type?: string}
export def "folders id-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --name: string # The optional new name for this folder.  The following restrictions to folder names apply: names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), names with trailing spaces, and names `.` and `..` are not allowed.  Folder names must be unique within their parent folder. The name check is case-insensitive, so a folder named `New Folder` cannot be created in a parent folder that already contains a folder named `new folder`. (e.g. New Folder)
  --description: string # The optional description of this folder. (e.g. Legal contracts for the new ACME deal)
  --sync-state: string@sync-state-completer # Specifies whether a folder should be synced to a user's device or not. This is used by Box Sync (discontinued) and is not used by Box Drive. (e.g. synced)
  --can-non-owners-invite: string@bool-completer # Specifies if users who are not the owner of the folder can invite new collaborators to the folder. (e.g. true)
  --parent: any
  --shared-link: any
  --folder-upload-email: any # nullable
  --tags: list # The tags for this item. These tags are shown in the Box web app and mobile apps next to an item.  To add or remove a tag, retrieve the item's current tags, modify them, and then update this field.  There is a limit of 100 tags per item, and 10,000 unique tags per enterprise. (e.g. [approved])
  --is-collaboration-restricted-to-enterprise: string@bool-completer # Specifies if new invites to this folder are restricted to users within the enterprise. This does not affect existing collaborations. (e.g. true)
  --collections: list # An array of collections to make this folder a member of. Currently we only support the `favorites` collection.  To get the ID for a collection, use the [List all collections][1] endpoint.  Passing an empty array `[]` or `null` will remove the folder from all collections.  [1]: https://developer.box.com/reference/get-collections (nullable) — item shape: {id?: string, type?: string}
  --can-non-owners-view-collaborators: string@bool-completer # Restricts collaborators who are not the owner of this folder from viewing other collaborations on this folder.  It also restricts non-owners from inviting new collaborators.  When setting this field to `false`, it is required to also set `can_non_owners_invite_collaborators` to `false` if it has not already been set. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)" $qp)
  let body = {name: $name, description: $description, sync_state: $sync_state, can_non_owners_invite: $can_non_owners_invite, parent: $parent, shared_link: $shared_link, folder_upload_email: $folder_upload_email, tags: $tags, is_collaboration_restricted_to_enterprise: $is_collaboration_restricted_to_enterprise, collections: $collections, can_non_owners_view_collaborators: $can_non_owners_view_collaborators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete folder
#
# DELETE /folders/{folder_id}
# operationId: delete_folders_id
export def "folders id-by-folder_id-3" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recursive: string@bool-completer # Delete a folder that is not empty by recursively deleting the folder and all of its content. (e.g. true)
  --if-match: string # Ensures this item hasn't recently changed before making changes.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recursive" $recursive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)" $qp)
  let extra_headers = {"if-match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List folder app item associations
#
# GET /folders/{folder_id}/app_item_associations
# operationId: get_folders_id_app_item_associations
export def "folders-app-item-associations associations" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --application-type: string # If given, returns only app items for this application type. (e.g. hubs)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "application_type" $application_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)/app_item_associations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested.  Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?fields=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --usemarker: string@bool-completer # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time.  By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --offset: int # The offset of the item at which to begin the response.  Offset-based pagination is not guaranteed to work reliably for high offset values and may fail for large datasets. In those cases, use marker-based pagination by setting `usemarker` to `true`. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --qp-sort: string@sort-completer # Defines the **second** attribute by which items are sorted.  The folder type affects the way the items are sorted:    * **Standard folder**:   Items are always sorted by   their `type` first, with   folders listed before files,   and files listed   before web links.    * **Root folder**:   This parameter is not supported   for marker-based pagination   on the root folder    (the folder with an `id` of `0`).    * **Shared folder with parent path   to the associated folder visible to   the collaborator**:   Items are always sorted by   their `type` first, with   folders listed before files,   and files listed   before web links. (e.g. id)
  --direction: string@direction-completer # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "usemarker" $usemarker "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)/items" $qp)
  let extra_headers = {"boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create folder
#
# POST /folders
# operationId: post_folders
# --parent shape: {id: string}
export def "folders folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  name: string # The name for the new folder.  The following restrictions to folder names apply: names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), names with trailing spaces, and names `.` and `..` are not allowed.  Folder names must be unique within their parent folder. The name check is case-insensitive, so a folder named `New Folder` cannot be created in a parent folder that already contains a folder named `new folder`. (e.g. New Folder)
  parent: record # The parent folder to create the new folder within. — shape: {id: string}
  --folder-upload-email: any
  --sync-state: string@sync-state-completer # Specifies whether a folder should be synced to a user's device or not. This is used by Box Sync (discontinued) and is not used by Box Drive. (e.g. synced)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/folders" $qp)
  let body = {name: $name, parent: $parent, folder_upload_email: $folder_upload_email, sync_state: $sync_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the copied folder.  There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), as well as names with trailing spaces are prohibited.  Additionally, the names `.` and `..` are not allowed either. (e.g. New Folder)
  parent: record # The destination folder to copy the folder to. — shape: {id: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)/copy" $qp)
  let body = {name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)/collaborations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trashed folder
#
# GET /folders/{folder_id}/trash
# operationId: get_folders_id_trash
export def "folders-trash trash-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<id: string, etag: string, type: string, sequence_id: record, name: string, created_at: string, modified_at: string, description: record, size: int, path_collection: record<total_count: int, entries: list<record>>, created_by: record, modified_by: record, trashed_at: string, purged_at: string, content_created_at: string, content_modified_at: string, owned_by: record, shared_link: string, folder_upload_email: string, parent: record, item_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)/trash" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently remove folder
#
# DELETE /folders/{folder_id}/trash
# operationId: delete_folders_id_trash
export def "folders-trash trash-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/trash")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --view: string # Taxonomy field values are returned in `API view` by default, meaning  the value is represented with a taxonomy node identifier.  To retrieve the `Hydrated view`, where taxonomy values are represented  with the full taxonomy node information, set this parameter to `hydrated`.  This is the only supported value for this parameter. (e.g. hydrated)
]: nothing -> record<entries: list<record>, limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get classification on folder
#
# GET /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: get_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Box__Security__Classification__Key: string, _parent: string, _template: string, _scope: string, _version: int, _type: string, _typeVersion: float, _canEdit: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add classification to folder
#
# POST /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: post_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Box-Security--Classification--Key: string # The name of the classification to apply to this folder.  To list the available classifications in an enterprise, use the classification API to retrieve the [classification template](https://developer.box.com/reference/get-metadata-templates-enterprise-securityClassification-6VMVochwUWo-schema) which lists all available classification keys. (e.g. Sensitive)
]: any -> record<Box__Security__Classification__Key: string, _parent: string, _template: string, _scope: string, _version: int, _type: string, _typeVersion: float, _canEdit: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let body = {Box__Security__Classification__Key: $Box_Security__Classification__Key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update classification on folder
#
# PUT /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: put_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<Box__Security__Classification__Key: string, _parent: string, _template: string, _scope: string, _version: int, _type: string, _typeVersion: float, _canEdit: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json-patch+json" $body
}

# Remove classification from folder
#
# DELETE /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: delete_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "folders-metadata-enterprise-security-classification-6vm-vochw-u-wo securityClassification-6VMVochwUWo-by-folder_id-3" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/enterprise/securityClassification-6VMVochwUWo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metadata instance on folder
#
# GET /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: get_folders_id_metadata_id_id
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/($scope)/($template_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create metadata instance on folder
#
# POST /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: post_folders_id_metadata_id_id
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
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/($scope)/($template_key)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update metadata instance on folder
#
# PUT /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: put_folders_id_metadata_id_id
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
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/($scope)/($template_key)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json-patch+json" $body
}

# Remove metadata instance from folder
#
# DELETE /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: delete_folders_id_metadata_id_id
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
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/metadata/($scope)/($template_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --usemarker: string@bool-completer # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time.  By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --direction: string@direction-completer # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
  --qp-sort: string@sort-completer-1 # Defines the **second** attribute by which items are sorted.  Items are always sorted by their `type` first, with folders listed before files, and files listed before web links.  This parameter is not supported when using marker-based pagination. (e.g. name)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "usemarker" $usemarker "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folders/trash/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get watermark for folder
#
# GET /folders/{folder_id}/watermark
# operationId: get_folders_id_watermark
export def "folders-watermark watermark-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<watermark: record<created_at: string, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply watermark to folder
#
# PUT /folders/{folder_id}/watermark
# operationId: put_folders_id_watermark
# --watermark shape: {imprint: "default"}
export def "folders-watermark watermark-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  watermark: record # The watermark to imprint on the folder. — shape: {imprint: "default"}
]: any -> record<watermark: record<created_at: string, modified_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/watermark")
  let body = {watermark: $watermark} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove watermark from folder
#
# DELETE /folders/{folder_id}/watermark
# operationId: delete_folders_id_watermark
export def "folders-watermark watermark-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_id)/watermark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List folder locks
#
# GET /folder_locks
# operationId: get_folder_locks
export def "folder-locks locks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folder-id: string # The unique identifier that represent a folder.  The ID for any folder can be determined by visiting this folder in the web application and copying the ID from the URL. For example, for the URL `https://*.app.box.com/folder/123` the `folder_id` is `123`.  The root folder of a Box account is always represented by the ID `0`. (e.g. 12345)
]: nothing -> record<entries: table<folder: record, id: string, type: string, created_by: record, created_at: string, locked_operations: record, lock_type: string>, limit: string, next_marker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folder_id" $folder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folder_locks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create folder lock
#
# POST /folder_locks
# operationId: post_folder_locks
# --locked_operations shape: {move: bool, delete: bool}
# --folder shape: {type: string, id: string}
export def "folder-locks locks-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locked-operations: record # The operations to lock for the folder. If `locked_operations` is included in the request, both `move` and `delete` must also be included and both set to `true`. — shape: {move: bool, delete: bool}
  folder: record # The folder to apply the lock to. — shape: {type: string, id: string}
]: any -> record<folder: record, id: string, type: string, created_by: record<id: string, type: string>, created_at: string, locked_operations: record<move: bool, delete: bool>, lock_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/folder_locks")
  let body = {locked_operations: $locked_operations, folder: $folder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folder_locks/($folder_lock_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --metadata-instance-id: string # The ID of an instance of the metadata template to find. (format: uuid, e.g. 01234500-12f1-1234-aa12-b1d234cb567e)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata_instance_id" $metadata_instance_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all classifications
#
# GET /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# operationId: get_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema
export def "metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, copyInstanceOnItemCopy: bool, fields: table<id: string, type: string, key: string, displayName: string, hidden: bool, options: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --body: record
]: any -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, copyInstanceOnItemCopy: bool, fields: table<id: string, type: string, key: string, displayName: string, hidden: bool, options: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#add")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --body: record
]: any -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, copyInstanceOnItemCopy: bool, fields: table<id: string, type: string, key: string, displayName: string, hidden: bool, options: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema#update")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json-patch+json" $body
}

# Get metadata template by name
#
# GET /metadata_templates/{scope}/{template_key}/schema
# operationId: get_metadata_templates_id_id_schema
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
]: nothing -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, fields: list<record>, copyInstanceOnItemCopy: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_templates/($scope)/($template_key)/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update metadata template
#
# PUT /metadata_templates/{scope}/{template_key}/schema
# operationId: put_metadata_templates_id_id_schema
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
  --body: record
]: any -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, fields: list<record>, copyInstanceOnItemCopy: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_templates/($scope)/($template_key)/schema")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json-patch+json" $body
}

# Remove metadata template
#
# DELETE /metadata_templates/{scope}/{template_key}/schema
# operationId: delete_metadata_templates_id_id_schema
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
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_templates/($scope)/($template_key)/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, fields: list<record>, copyInstanceOnItemCopy: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_templates/global" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata_templates/enterprise" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create metadata template
#
# POST /metadata_templates/schema
# operationId: post_metadata_templates_schema
# --fields item shape: {type: "string"|"float"|"date"|"enum"|"multiSelect"|"taxonomy", key: string, displayName: string, description?: string, hidden?: bool, options?: list, taxonomyKey?: string, taxonomyId?: string, namespace?: string, optionsRules?: record}
export def "metadata-templates-schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scope: string # The scope of the metadata template to create. Applications can only create templates for use within the authenticated user's enterprise.  This value needs to be set to `enterprise`, as `global` scopes can not be created by applications. (e.g. enterprise)
  --templateKey: string # A unique identifier for the template. This identifier needs to be unique across the enterprise for which the metadata template is being created.  When not provided, the API will create a unique `templateKey` based on the value of the `displayName`. (e.g. productInfo)
  displayName: string # The display name of the template. (e.g. Product Info)
  --hidden: string@bool-completer # Defines if this template is visible in the Box web app UI, or if it is purely intended for usage through the API. (default: false, e.g. true)
  --body-fields: list # An ordered list of template fields which are part of the template. Each field can be a regular text field, date field, number field, as well as a single or multi-select list. — item shape: {type: "string"|"float"|"date"|"enum"|"multiSelect"|"taxonomy", key: string, displayName: string, description?: string, hidden?: bool, options?: list, taxonomyKey?: string, taxonomyId?: string, namespace?: string, optionsRules?: record}
  --copyInstanceOnItemCopy: string@bool-completer # Whether or not to copy any metadata attached to a file or folder when it is copied. By default, metadata is not copied along with a file or folder when it is copied. (default: false, e.g. true)
]: any -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, fields: list<record>, copyInstanceOnItemCopy: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/schema")
  let body = {scope: $scope, templateKey: $templateKey, displayName: $displayName, hidden: $hidden, fields: $body_fields, copyInstanceOnItemCopy: $copyInstanceOnItemCopy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add initial classifications
#
# POST /metadata_templates/schema#classifications
# operationId: post_metadata_templates_schema#classifications
# --fields item shape: {type: "enum", key: "Box__Security__Classification__Key", displayName: "Classification", hidden?: bool, options: list}
export def "metadata-templates-schemaclassifications schemaclassifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scope: string@scope-completer # The scope in which to create the classifications. This should be `enterprise` or `enterprise_{id}` where `id` is the unique ID of the enterprise. (e.g. enterprise)
  templateKey: string@templateKey-completer # Defines the list of metadata templates. (e.g. securityClassification-6VMVochwUWo)
  displayName: string@displayName-completer # The name of the template as shown in web and mobile interfaces. (e.g. Classification)
  --hidden: string@bool-completer # Determines if the classification template is hidden or available on web and mobile devices. (e.g. false)
  --copyInstanceOnItemCopy: string@bool-completer # Determines if classifications are copied along when the file or folder is copied. (e.g. false)
  --body-fields: list # The classification template requires exactly one field, which holds all the valid classification values. — item shape: {type: "enum", key: "Box__Security__Classification__Key", displayName: "Classification", hidden?: bool, options: list}
]: any -> record<id: string, type: string, scope: string, templateKey: string, displayName: string, hidden: bool, copyInstanceOnItemCopy: bool, fields: table<id: string, type: string, key: string, displayName: string, hidden: bool, options: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_templates/schema#classifications")
  let body = {scope: $scope, templateKey: $templateKey, displayName: $displayName, hidden: $hidden, copyInstanceOnItemCopy: $copyInstanceOnItemCopy, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  folder_id: string # The ID of the folder to apply the policy to. This folder will need to already have an instance of the targeted metadata template applied to it. (e.g. 1234567)
  scope: string@scope-completer-1 # The scope of the targeted metadata template. This template will need to already have an instance applied to the targeted folder. (e.g. enterprise)
  templateKey: string # The key of the targeted metadata template. This template will need to already have an instance applied to the targeted folder.  In many cases the template key is automatically derived of its display name, for example `Contract Template` would become `contractTemplate`. In some cases the creator of the template will have provided its own template key.  Please [list the templates for an enterprise][list], or get all instances on a [file][file] or [folder][folder] to inspect a template's key.  [list]: https://developer.box.com/reference/get-metadata-templates-enterprise [file]: https://developer.box.com/reference/get-files-id-metadata [folder]: https://developer.box.com/reference/get-folders-id-metadata (e.g. productInfo)
]: any -> record<id: string, type: string, owner_enterprise: record<type: string, id: string>, parent: record<type: string, id: string>, scope: string, templateKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_cascade_policies")
  let body = {folder_id: $folder_id, scope: $scope, templateKey: $templateKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metadata cascade policy
#
# GET /metadata_cascade_policies/{metadata_cascade_policy_id}
# operationId: get_metadata_cascade_policies_id
export def "metadata-cascade-policies id-by-metadata_cascade_policy_id" [
  metadata_cascade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, owner_enterprise: record<type: string, id: string>, parent: record<type: string, id: string>, scope: string, templateKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_cascade_policies/($metadata_cascade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove metadata cascade policy
#
# DELETE /metadata_cascade_policies/{metadata_cascade_policy_id}
# operationId: delete_metadata_cascade_policies_id
export def "metadata-cascade-policies id-by-metadata_cascade_policy_id-1" [
  metadata_cascade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_cascade_policies/($metadata_cascade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  conflict_resolution: string@conflict-resolution-completer # Describes the desired behavior when dealing with the conflict where a metadata template already has an instance applied to a child.  * `none` will preserve the existing value on the file * `overwrite` will force-apply the templates values over   any existing values. (e.g. none)
]: any -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_cascade_policies/($metadata_cascade_policy_id)/apply")
  let body = {conflict_resolution: $conflict_resolution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query files/folders by metadata
#
# POST /metadata_queries/execute_read
# operationId: post_metadata_queries_execute_read
# --order_by item shape: {field_key?: string, direction?: "ASC"|"DESC"|"asc"|"desc"}
export def "metadata-queries-execute-read read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: string # Specifies the template used in the query. Must be in the form `scope.templateKey`. Not all templates can be used in this field, most notably the built-in, Box-provided classification templates can not be used in a query. (e.g. enterprise_123456.someTemplate)
  --body-query: string # The query to perform. A query is a logical expression that is very similar to a SQL `SELECT` statement. Values in the search query can be turned into parameters specified in the `query_param` arguments list to prevent having to manually insert search values into the query string.  For example, a value of `:amount` would represent the `amount` value in `query_params` object. (e.g. value >= :amount)
  --query-params: record # Set of arguments corresponding to the parameters specified in the `query`. The type of each parameter used in the `query_params` must match the type of the corresponding metadata template field. (e.g. {amount: 100})
  ancestor_folder_id: string # The ID of the folder that you are restricting the query to. A value of zero will return results from all folders you have access to. A non-zero value will only return results found in the folder corresponding to the ID or in any of its subfolders. (e.g. 0)
  --order-by: list # A list of template fields and directions to sort the metadata query results by.  The ordering `direction` must be the same for each item in the array. — item shape: {field_key?: string, direction?: "ASC"|"DESC"|"asc"|"desc"}
  --limit: int # A value between 0 and 100 that indicates the maximum number of results to return for a single request. This only specifies a maximum boundary and will not guarantee the minimum number of results returned. (default: 100, e.g. 50)
  --marker: string # Marker to use for requesting the next page. (e.g. AAAAAmVYB1FWec8GH6yWu2nwmanfMh07IyYInaa7DZDYjgO1H4KoLW29vPlLY173OKsci6h6xGh61gG73gnaxoS+o0BbI1/h6le6cikjlupVhASwJ2Cj0tOD9wlnrUMHHw3/ISf+uuACzrOMhN6d5fYrbidPzS6MdhJOejuYlvsg4tcBYzjauP3+VU51p77HFAIuObnJT0ff)
  --body-fields: list # By default, this endpoint returns only the most basic info about the items for which the query matches. This attribute can be used to specify a list of additional attributes to return for any item, including its metadata.  This attribute takes a list of item fields, metadata template identifiers, or metadata template field identifiers.  For example:  * `created_by` will add the details of the user who created the item to the response. * `metadata.<scope>.<templateKey>` will return the mini-representation of the metadata instance identified by the `scope` and `templateKey`. * `metadata.<scope>.<templateKey>.<field>` will return all the mini-representation of the metadata instance identified by the `scope` and `templateKey` plus the field specified by the `field` name. Multiple fields for the same `scope` and `templateKey` can be defined. (e.g. [extension, created_at, item_status, metadata.enterprise_1234.contracts, metadata.enterprise_1234.regions.location])
]: any -> record<entries: list<record>, limit: int, next_marker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_queries/execute_read")
  let body = {from: $body_from, query: $body_query, query_params: $query_params, ancestor_folder_id: $ancestor_folder_id, order_by: $order_by, limit: $limit, marker: $marker, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get comment
#
# GET /comments/{comment_id}
# operationId: get_comments_id
export def "comments id-by-comment_id" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($comment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update comment
#
# PUT /comments/{comment_id}
# operationId: put_comments_id
export def "comments id-by-comment_id-1" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --message: string # The text of the comment to update. (e.g. Review completed!)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/($comment_id)" $qp)
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove comment
#
# DELETE /comments/{comment_id}
# operationId: delete_comments_id
export def "comments id-by-comment_id-2" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create comment
#
# POST /comments
# operationId: post_comments
# --item shape: {id: string, type: "file"|"comment"}
export def "comments comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  message: string # The text of the comment.  To mention a user, use the `tagged_message` parameter instead. (e.g. Review completed!)
  --tagged-message: string # The text of the comment, including `@[user_id:name]` somewhere in the message to mention another user, which will send them an email notification, letting them know they have been mentioned.  The `user_id` is the target user's ID, where the `name` can be any custom phrase. In the Box UI this name will link to the user's profile.  If you are not mentioning another user, use `message` instead. (e.g. @[1234:John] Review completed!)
  item: record # The item to attach the comment to. — shape: {id: string, type: "file"|"comment"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/comments" $qp)
  let body = {message: $message, tagged_message: $tagged_message, item: $item} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get collaboration
#
# GET /collaborations/{collaboration_id}
# operationId: get_collaborations_id
export def "collaborations id-by-collaboration_id" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<id: string, type: string, item: record, app_item: record<id: string, type: string, application_type: string>, accessible_by: record, invite_email: string, role: string, expires_at: string, is_access_only: bool, status: string, acknowledged_at: string, created_by: record, created_at: string, modified_at: string, acceptance_requirements_status: record<terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/collaborations/($collaboration_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update collaboration
#
# PUT /collaborations/{collaboration_id}
# operationId: put_collaborations_id
export def "collaborations id-by-collaboration_id-1" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer # The level of access granted. (e.g. editor)
  --status: string@status-completer-1 # Set the status of a `pending` collaboration invitation, effectively accepting, or rejecting the invite. (e.g. accepted)
  --expires-at: string # Update the expiration date for the collaboration. At this date, the collaboration will be automatically removed from the item.  This feature will only work if the **Automatically remove invited collaborators: Allow folder owners to extend the expiry date** setting has been enabled in the **Enterprise Settings** of the **Admin Console**. When the setting is not enabled, collaborations can not have an expiry date and a value for this field will be result in an error.  Additionally, a collaboration can only be given an expiration if it was created after the **Automatically remove invited collaborator** setting was enabled. (format: date-time, e.g. 2019-08-29T23:59:00-07:00)
  --can-view-path: string@bool-completer # Determines if the invited users can see the entire parent path to the associated folder. The user will not gain privileges in any parent folder and therefore can not see content the user is not collaborated on.  Be aware that this meaningfully increases the time required to load the invitee's **All Files** page. We recommend you limit the number of collaborations with `can_view_path` enabled to 1,000 per user.  Only an owner or co-owners can invite collaborators with a `can_view_path` of `true`. Only an owner can update `can_view_path` on existing collaborations.  `can_view_path` can only be used for folder collaborations.  When you delete a folder with `can_view_path=true`, collaborators may still see the parent path.  For instructions on how to remove this, see  [Even though a folder invited via can_view_path is deleted, the path remains displayed](https://support.box.com/hc/en-us/articles/37472814319891-Even-though-a-folder-invited-via-can-view-path-is-deleted-the-path-remains-displayed). (e.g. true)
]: any -> record<id: string, type: string, item: record, app_item: record<id: string, type: string, application_type: string>, accessible_by: record, invite_email: string, role: string, expires_at: string, is_access_only: bool, status: string, acknowledged_at: string, created_by: record, created_at: string, modified_at: string, acceptance_requirements_status: record<terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaborations/($collaboration_id)")
  let body = {role: $role, status: $status, expires_at: $expires_at, can_view_path: $can_view_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove collaboration
#
# DELETE /collaborations/{collaboration_id}
# operationId: delete_collaborations_id
export def "collaborations id-by-collaboration_id-2" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaborations/($collaboration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pending collaborations
#
# GET /collaborations
# operationId: get_collaborations
export def "collaborations collaborations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # The status of the collaborations to retrieve. (e.g. pending)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaborations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create collaboration
#
# POST /collaborations
# operationId: post_collaborations
# --item shape: {type?: "file"|"folder", id?: string}
# --accessible_by shape: {type: "user"|"group", id?: string, login?: string}
export def "collaborations collaborations-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --notify: string@bool-completer # Determines if users should receive email notification for the action performed. (e.g. true)
  item: record # The item to attach the comment to. — shape: {type?: "file"|"folder", id?: string}
  accessible_by: record # The user or group to give access to the item. — shape: {type: "user"|"group", id?: string, login?: string}
  role: string@role-completer-1 # The level of access granted. (e.g. editor)
  --is-access-only: string@bool-completer # If set to `true`, collaborators have access to shared items, but such items won't be visible in the All Files list. Additionally, collaborators won't see the path to the root folder for the shared item. (e.g. true)
  --can-view-path: string@bool-completer # Determines if the invited users can see the entire parent path to the associated folder. The user will not gain privileges in any parent folder and therefore can not see content the user is not collaborated on.  Be aware that this meaningfully increases the time required to load the invitee's **All Files** page. We recommend you limit the number of collaborations with `can_view_path` enabled to 1,000 per user.  Only an owner or co-owners can invite collaborators with a `can_view_path` of `true`. Only an owner can update `can_view_path` on existing collaborations.  `can_view_path` can only be used for folder collaborations.  When you delete a folder with `can_view_path=true`, collaborators may still see the parent path.  For instructions on how to remove this, see  [Even though a folder invited via can_view_path is deleted, the path remains displayed](https://support.box.com/hc/en-us/articles/37472814319891-Even-though-a-folder-invited-via-can-view-path-is-deleted-the-path-remains-displayed). (e.g. true)
  --expires-at: string # Set the expiration date for the collaboration. At this date, the collaboration will be automatically removed from the item.  This feature will only work if the **Automatically remove invited collaborators: Allow folder owners to extend the expiry date** setting has been enabled in the **Enterprise Settings** of the **Admin Console**. When the setting is not enabled, collaborations can not have an expiry date and a value for this field will be result in an error. (format: date-time, e.g. 2019-08-29T23:59:00-07:00)
]: any -> record<id: string, type: string, item: record, app_item: record<id: string, type: string, application_type: string>, accessible_by: record, invite_email: string, role: string, expires_at: string, is_access_only: bool, status: string, acknowledged_at: string, created_by: record, created_at: string, modified_at: string, acceptance_requirements_status: record<terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaborations" $qp)
  let body = {item: $item, accessible_by: $accessible_by, role: $role, is_access_only: $is_access_only, can_view_path: $can_view_path, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for content
#
# GET /search
# operationId: get_search
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The string to search for. This query is matched against item names, descriptions, text content of files, and various other fields of the different item types.  This parameter supports a variety of operators to further refine the results returns.  * `""` - by wrapping a query in double quotes only exact matches are   returned by the API. Exact searches do not return search matches   based on specific character sequences. Instead, they return   matches based on phrases, that is, word sequences. For example:   A search for `"Blue-Box"` may return search results including   the sequence `"blue.box"`, `"Blue Box"`, and `"Blue-Box"`;   any item containing the words `Blue` and `Box` consecutively, in   the order specified. * `AND` - returns items that contain both the search terms. For   example, a search for `marketing AND BoxWorks` returns items   that have both `marketing` and `BoxWorks` within its text in any order.   It does not return a result that only has `BoxWorks` in its text. * `OR` - returns items that contain either of the search terms. For   example, a search for `marketing OR BoxWorks` returns a result that   has either `marketing` or `BoxWorks` within its text. Using this   operator is not necessary as we implicitly interpret multi-word   queries as `OR` unless another supported boolean term is used. * `NOT` - returns items that do not contain the search term provided.   For example, a search for `marketing AND NOT BoxWorks` returns a result   that has only `marketing` within its text. Results containing   `BoxWorks` are omitted.  We do not support lower case (that is, `and`, `or`, and `not`) or mixed case (that is, `And`, `Or`, and `Not`) operators.  This field is required unless the `mdfilters` parameter is defined. (e.g. sales)
  --scope: string@scope-completer-2 # Limits the search results to either the files that the user has access to, or to files available to the entire enterprise.  The scope defaults to `user_content`, which limits the search results to content that is available to the currently authenticated user.  The `enterprise_content` can be requested by an admin through our support channels. Once this scope has been enabled for a user, it will allow that use to query for content across the entire enterprise and not only the content that they have access to. (default: user_content, e.g. user_content)
  --file-extensions: list # Limits the search results to any files that match any of the provided file extensions. This list is a comma-separated list of file extensions without the dots. (e.g. [pdf, png, gif])
  --created-at-range: list # Limits the search results to any items created within a given date range.  Date ranges are defined as comma separated RFC3339 timestamps.  If the start date is omitted (`,2014-05-17T13:35:01-07:00`) anything created before the end date will be returned.  If the end date is omitted (`2014-05-15T13:35:01-07:00,`) the current date will be used as the end date instead. (e.g. [2014-05-15T13:35:01-07:00, 2014-05-17T13:35:01-07:00])
  --updated-at-range: list # Limits the search results to any items updated within a given date range.  Date ranges are defined as comma separated RFC3339 timestamps.  If the start date is omitted (`,2014-05-17T13:35:01-07:00`) anything updated before the end date will be returned.  If the end date is omitted (`2014-05-15T13:35:01-07:00,`) the current date will be used as the end date instead. (e.g. [2014-05-15T13:35:01-07:00, 2014-05-17T13:35:01-07:00])
  --size-range: list # Limits the search results to any items with a size within a given file size range. This applied to files and folders.  Size ranges are defined as comma separated list of a lower and upper byte size limit (inclusive).  The upper and lower bound can be omitted to create open ranges. (e.g. [1000000, 5000000])
  --owner-user-ids: list # Limits the search results to any items that are owned by the given list of owners, defined as a list of comma separated user IDs.  The items still need to be owned or shared with the currently authenticated user for them to show up in the search results. If the user does not have access to any files owned by any of the users an empty result set will be returned.  To search across an entire enterprise, we recommend using the `enterprise_content` scope parameter which can be requested with our support team. (e.g. [123422, 23532, 3241212])
  --recent-updater-user-ids: list # Limits the search results to any items that have been updated by the given list of users, defined as a list of comma separated user IDs.  The items still need to be owned or shared with the currently authenticated user for them to show up in the search results. If the user does not have access to any files owned by any of the users an empty result set will be returned.  This feature only searches back to the last 10 versions of an item. (e.g. [123422, 23532, 3241212])
  --ancestor-folder-ids: list # Limits the search results to items within the given list of folders, defined as a comma separated lists of folder IDs.  Search results will also include items within any subfolders of those ancestor folders.  The folders still need to be owned or shared with the currently authenticated user. If the folder is not accessible by this user, or it does not exist, a `HTTP 404` error code will be returned instead.  To search across an entire enterprise, we recommend using the `enterprise_content` scope parameter which can be requested with our support team. (e.g. [4535234, 234123235, 2654345])
  --content-types: list # Limits the search results to any items that match the search query for a specific part of the file, for example the file description.  Content types are defined as a comma separated lists of Box recognized content types. The allowed content types are as follows.  * `name` - The name of the item, as defined by its `name` field. * `description` - The description of the item, as defined by its   `description` field. * `file_content` - The actual content of the file. * `comments` - The content of any of the comments on a file or    folder. * `tags` - Any tags that are applied to an item, as defined by its    `tags` field. (e.g. [name, description])
  --type: string@type-completer-1 # Limits the search results to any items of this type. This parameter only takes one value. By default the API returns items that match any of these types.  * `file` - Limits the search results to files, * `folder` - Limits the search results to folders, * `web_link` - Limits the search results to web links, also known    as bookmarks. (e.g. file)
  --trash-content: string@trash-content-completer # Determines if the search should look in the trash for items.  By default, this API only returns search results for items not currently in the trash (`non_trashed_only`).  * `trashed_only` - Only searches for items currently in the trash * `non_trashed_only` - Only searches for items currently not in   the trash * `all_items` - Searches for both trashed and non-trashed items. (default: non_trashed_only, e.g. non_trashed_only)
  --mdfilters: list # Limits the search results to any items for which the metadata matches the provided filter. This parameter is a list that specifies exactly **one** metadata template used to filter the search results. The parameter is required unless the `query` parameter is provided. (e.g. [{scope: enterprise, templateKey: contract, filters: [{category: online}, {contractValue: 100000}]}])
  --qp-sort: string@sort-completer-2 # Defines the order in which search results are returned. This API defaults to returning items by relevance unless this parameter is explicitly specified.  * `relevance` (default) returns the results sorted by relevance to the query search term. The relevance is based on the occurrence of the search term in the items name, description, content, and additional properties. * `modified_at` returns the results ordered in descending order by date at which the item was last modified. (default: relevance, e.g. modified_at)
  --direction: string@direction-completer # Defines the direction in which search results are ordered. This API defaults to returning items in descending (`DESC`) order unless this parameter is explicitly specified.  When results are sorted by `relevance` the ordering is locked to returning items in descending order of relevance, and this parameter is ignored. (default: DESC, e.g. ASC)
  --limit: int # Defines the maximum number of items to return as part of a page of results. (format: int64, default: 30, e.g. 100)
  --include-recent-shared-links: string@bool-completer # Defines whether the search results should include any items that the user recently accessed through a shared link.  When this parameter has been set to true, the format of the response of this API changes to return a list of [Search Results with Shared Links](https://developer.box.com/reference/resources/search-results-with-shared-links). (default: false, e.g. true)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --deleted-user-ids: list # Limits the search results to items that were deleted by the given list of users, defined as a list of comma separated user IDs.  The `trash_content` parameter needs to be set to `trashed_only`.  If searching in trash is not performed, an empty result set is returned. The items need to be owned or shared with the currently authenticated user for them to show up in the search results.  If the user does not have access to any files owned by any of the users, an empty result set is returned.  Data available from 2023-02-01 onwards. (e.g. [123422, 23532, 3241212])
  --deleted-at-range: list # Limits the search results to any items deleted within a given date range.  Date ranges are defined as comma separated RFC3339 timestamps.  If the start date is omitted (`2014-05-17T13:35:01-07:00`), anything deleted before the end date will be returned.  If the end date is omitted (`2014-05-15T13:35:01-07:00`), the current date will be used as the end date instead.  The `trash_content` parameter needs to be set to `trashed_only`.  If searching in trash is not performed, then an empty result is returned.  Data available from 2023-02-01 onwards. (e.g. [2014-05-15T13:35:01-07:00, 2014-05-17T13:35:01-07:00])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "file_extensions" $file_extensions "csv") (serialize-qp "created_at_range" $created_at_range "csv") (serialize-qp "updated_at_range" $updated_at_range "csv") (serialize-qp "size_range" $size_range "csv") (serialize-qp "owner_user_ids" $owner_user_ids "csv") (serialize-qp "recent_updater_user_ids" $recent_updater_user_ids "csv") (serialize-qp "ancestor_folder_ids" $ancestor_folder_ids "csv") (serialize-qp "content_types" $content_types "csv") (serialize-qp "type" $type "scalar") (serialize-qp "trash_content" $trash_content "scalar") (serialize-qp "mdfilters" $mdfilters "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include_recent_shared_links" $include_recent_shared_links "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "deleted_user_ids" $deleted_user_ids "multi") (serialize-qp "deleted_at_range" $deleted_at_range "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create task
#
# POST /tasks
# operationId: post_tasks
# --item shape: {id?: string, type?: "file"}
export def "tasks tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  item: record # The file to attach the task to. — shape: {id?: string, type?: "file"}
  --action: string@action-completer # The action the task assignee will be prompted to do. Must be  * `review` defines an approval task that can be approved or, rejected * `complete` defines a general task which can be completed. (default: review, e.g. review)
  --message: string # An optional message to include with the task. (default: , e.g. Please review)
  --due-at: string # Defines when the task is due. Defaults to `null` if not provided. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --completion-rule: string@completion-rule-completer # Defines which assignees need to complete this task before the task is considered completed.  * `all_assignees` (default) requires all assignees to review or approve the task in order for it to be considered completed. * `any_assignee` accepts any one assignee to review or approve the task in order for it to be considered completed. (default: all_assignees, e.g. all_assignees)
]: any -> record<id: string, type: string, item: record, due_at: string, action: string, message: string, task_assignment_collection: record<total_count: int, entries: list<record>>, is_completed: bool, created_by: record, created_at: string, completion_rule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks")
  let body = {item: $item, action: $action, message: $message, due_at: $due_at, completion_rule: $completion_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get task
#
# GET /tasks/{task_id}
# operationId: get_tasks_id
export def "tasks id-by-task_id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, item: record, due_at: string, action: string, message: string, task_assignment_collection: record<total_count: int, entries: list<record>>, is_completed: bool, created_by: record, created_at: string, completion_rule: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update task
#
# PUT /tasks/{task_id}
# operationId: put_tasks_id
export def "tasks id-by-task_id-1" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer # The action the task assignee will be prompted to do. Must be  * `review` defines an approval task that can be approved or rejected, * `complete` defines a general task which can be completed. (e.g. review)
  --message: string # The message included with the task. (e.g. Please review)
  --due-at: string # When the task is due at. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --completion-rule: string@completion-rule-completer # Defines which assignees need to complete this task before the task is considered completed.  * `all_assignees` (default) requires all assignees to review or approve the task in order for it to be considered completed. * `any_assignee` accepts any one assignee to review or approve the task in order for it to be considered completed. (e.g. all_assignees)
]: any -> record<id: string, type: string, item: record, due_at: string, action: string, message: string, task_assignment_collection: record<total_count: int, entries: list<record>>, is_completed: bool, created_by: record, created_at: string, completion_rule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($task_id)")
  let body = {action: $action, message: $message, due_at: $due_at, completion_rule: $completion_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove task
#
# DELETE /tasks/{task_id}
# operationId: delete_tasks_id
export def "tasks id-by-task_id-2" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<total_count: int, entries: table<id: string, type: string, item: record, assigned_to: record, message: string, completed_at: string, assigned_at: string, reminded_at: string, resolution_state: string, assigned_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($task_id)/assignments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign task
#
# POST /task_assignments
# operationId: post_task_assignments
# --task shape: {id: string, type: "task"}
# --assign_to shape: {id?: string, login?: string}
export def "task-assignments assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  task: record # The task to assign to a user. — shape: {id: string, type: "task"}
  assign_to: record # The user to assign the task to. — shape: {id?: string, login?: string}
]: any -> record<id: string, type: string, item: record, assigned_to: record, message: string, completed_at: string, assigned_at: string, reminded_at: string, resolution_state: string, assigned_by: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/task_assignments")
  let body = {task: $task, assign_to: $assign_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get task assignment
#
# GET /task_assignments/{task_assignment_id}
# operationId: get_task_assignments_id
export def "task-assignments id-by-task_assignment_id" [
  task_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, item: record, assigned_to: record, message: string, completed_at: string, assigned_at: string, reminded_at: string, resolution_state: string, assigned_by: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task_assignments/($task_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update task assignment
#
# PUT /task_assignments/{task_assignment_id}
# operationId: put_task_assignments_id
export def "task-assignments id-by-task_assignment_id-1" [
  task_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string # An optional message by the assignee that can be added to the task. (e.g. Looks good to me)
  --resolution-state: string@resolution-state-completer # The state of the task assigned to the user.  * For a task with an `action` value of `complete` this can be `incomplete` or `completed`. * For a task with an `action` of `review` this can be `incomplete`, `approved`, or `rejected`. (e.g. completed)
]: any -> record<id: string, type: string, item: record, assigned_to: record, message: string, completed_at: string, assigned_at: string, reminded_at: string, resolution_state: string, assigned_by: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task_assignments/($task_assignment_id)")
  let body = {message: $message, resolution_state: $resolution_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign task
#
# DELETE /task_assignments/{task_assignment_id}
# operationId: delete_task_assignments_id
export def "task-assignments id-by-task_assignment_id-2" [
  task_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task_assignments/($task_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link.  The format for this header is as follows:  `shared_link=[link]&shared_link_password=[password]`. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_items" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shared link for file
#
# GET /files/{file_id}#get_shared_link
# operationId: get_files_id#get_shared_link
export def "files link-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)#get_shared_link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add shared link to file
#
# PUT /files/{file_id}#add_shared_link
# operationId: put_files_id#add_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
export def "files link-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the file. Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)#add_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update shared link on file
#
# PUT /files/{file_id}#update_shared_link
# operationId: put_files_id#update_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
export def "files link-by-file_id-2" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)#update_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove shared link from file
#
# PUT /files/{file_id}#remove_shared_link
# operationId: put_files_id#remove_shared_link
export def "files link-by-file_id-3" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the file. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)#remove_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link.  The format for this header is as follows:  `shared_link=[link]&shared_link_password=[password]`. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_items#folders" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shared link for folder
#
# GET /folders/{folder_id}#get_shared_link
# operationId: get_folders_id#get_shared_link
export def "folders link-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)#get_shared_link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add shared link to folder
#
# PUT /folders/{folder_id}#add_shared_link
# operationId: put_folders_id#add_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
export def "folders link-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the folder.  Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)#add_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update shared link on folder
#
# PUT /folders/{folder_id}#update_shared_link
# operationId: put_folders_id#update_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
export def "folders link-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)#update_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove shared link from folder
#
# PUT /folders/{folder_id}#remove_shared_link
# operationId: put_folders_id#remove_shared_link
export def "folders link-by-folder_id-3" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the folder. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_id)#remove_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create web link
#
# POST /web_links
# operationId: post_web_links
# --parent shape: {id: string}
export def "web-links links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL that this web link links to. Must start with `"http://"` or `"https://"`. (e.g. https://box.com)
  parent: record # The parent folder to create the web link within. — shape: {id: string}
  --name: string # Name of the web link. Defaults to the URL if not set. (e.g. Box Website)
  --description: string # Description of the web link. (e.g. Cloud Content Management)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/web_links")
  let body = {url: $body_url, parent: $parent, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get web link
#
# GET /web_links/{web_link_id}
# operationId: get_web_links_id
export def "web-links id-by-web_link_id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --boxapi: string # The URL, and optional password, for the shared link of this item.  This header can be used to access items that have not been explicitly shared with a user.  Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`.  This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/web_links/($web_link_id)")
  let extra_headers = {"boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore web link
#
# POST /web_links/{web_link_id}
# operationId: post_web_links_id
export def "web-links id-by-web_link_id-1" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the web link. (e.g. Restored.docx)
  --parent: any
]: any -> record<type: string, id: string, sequence_id: record, etag: string, name: string, url: string, parent: record, description: string, path_collection: record<total_count: int, entries: list<record>>, created_at: string, modified_at: string, trashed_at: string, purged_at: string, created_by: record, modified_by: record, owned_by: record, shared_link: string, item_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/web_links/($web_link_id)" $qp)
  let body = {name: $name, parent: $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update web link
#
# PUT /web_links/{web_link_id}
# operationId: put_web_links_id
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string}
export def "web-links id-by-web_link_id-2" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The new URL that the web link links to. Must start with `"http://"` or `"https://"`. (e.g. https://box.com)
  --parent: any
  --name: string # A new name for the web link. Defaults to the URL if not set. (e.g. Box Website)
  --description: string # A new description of the web link. (e.g. Cloud Content Management)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/web_links/($web_link_id)")
  let body = {url: $body_url, parent: $parent, name: $name, description: $description, shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove web link
#
# DELETE /web_links/{web_link_id}
# operationId: delete_web_links_id
export def "web-links id-by-web_link_id-3" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/web_links/($web_link_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trashed web link
#
# GET /web_links/{web_link_id}/trash
# operationId: get_web_links_id_trash
export def "web-links-trash trash-by-web_link_id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<type: string, id: string, sequence_id: record, etag: string, name: string, url: string, parent: record, description: string, path_collection: record<total_count: int, entries: list<record>>, created_at: string, modified_at: string, trashed_at: string, purged_at: string, created_by: record, modified_by: record, owned_by: record, shared_link: string, item_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/web_links/($web_link_id)/trash" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently remove web link
#
# DELETE /web_links/{web_link_id}/trash
# operationId: delete_web_links_id_trash
export def "web-links-trash trash-by-web_link_id-1" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/web_links/($web_link_id)/trash")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed.  Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link.  The format for this header is as follows:  `shared_link=[link]&shared_link_password=[password]`. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_items#web_links" $qp)
  let extra_headers = {"if-none-match": $if_none_match, "boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shared link for web link
#
# GET /web_links/{web_link_id}#get_shared_link
# operationId: get_web_links_id#get_shared_link
export def "web-links link-by-web_link_id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/web_links/($web_link_id)#get_shared_link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add shared link to web link
#
# PUT /web_links/{web_link_id}#add_shared_link
# operationId: put_web_links_id#add_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
export def "web-links link-by-web_link_id-1" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the web link.  Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/web_links/($web_link_id)#add_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update shared link on web link
#
# PUT /web_links/{web_link_id}#update_shared_link
# operationId: put_web_links_id#update_shared_link
# --shared_link shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
export def "web-links link-by-web_link_id-2" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, vanity_name?: string, unshared_at?: string, permissions?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/web_links/($web_link_id)#update_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove shared link from web link
#
# PUT /web_links/{web_link_id}#remove_shared_link
# operationId: put_web_links_id#remove_shared_link
export def "web-links link-by-web_link_id-3" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Explicitly request the `shared_link` fields to be returned for this item. (e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the web link. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/web_links/($web_link_id)#remove_shared_link" $qp)
  let body = {shared_link: $shared_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find app item for shared link
#
# GET /shared_items#app_items
# operationId: get_shared_items#app_items
export def "shared-itemsapp-items items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --boxapi: string # A header containing the shared link and optional password for the shared link.  The format for this header is `shared_link=[link]&shared_link_password=[password]`. (e.g. shared_link=[example.com]&shared_link_password=[xyz123])
]: nothing -> record<id: string, type: string, application_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shared_items#app_items")
  let extra_headers = {"boxapi": $boxapi} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List enterprise users
#
# GET /users
# operationId: get_users
export def "users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter-term: string # Limits the results to only users who's `name` or `login` start with the search term.  For externally managed users, the search term needs to completely match the in order to find the user, and it will only return one user at a time. (e.g. john)
  --user-type: string@user-type-completer # Limits the results to the kind of user specified.  * `all` returns every kind of user for whom the   `login` or `name` partially matches the   `filter_term`. It will only return an external user   if the login matches the `filter_term` completely,   and in that case it will only return that user. * `managed` returns all managed and app users for whom   the `login` or `name` partially matches the   `filter_term`. * `external` returns all external users for whom the   `login` matches the `filter_term` exactly. (e.g. managed)
  --external-app-user-id: string # Limits the results to app users with the given `external_app_user_id` value.  When creating an app user, an `external_app_user_id` value can be set. This value can then be used in this endpoint to find any users that match that `external_app_user_id` value. (e.g. my-user-1234)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --usemarker: string@bool-completer # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time.  By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_term" $filter_term "scalar") (serialize-qp "user_type" $user_type "scalar") (serialize-qp "external_app_user_id" $external_app_user_id "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "usemarker" $usemarker "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user
#
# POST /users
# operationId: post_users
# --tracking_codes item shape: {type?: "tracking_code", name?: string, value?: string}
export def "users users-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  name: string # The name of the user. (e.g. Aaron Levie)
  --login: string # The email address the user uses to log in  Required, unless `is_platform_access_only` is set to `true`. (e.g. boss@box.com)
  --is-platform-access-only: string@bool-completer # Specifies that the user is an app user. (e.g. true)
  --role: string@role-completer-2 # The user’s enterprise role. (e.g. user)
  --language: string # The language of the user, formatted in modified version of the [ISO 639-1](https://developer.box.com/guides/api-calls/language-codes) format. (e.g. en)
  --is-sync-enabled: string@bool-completer # Whether the user can use Box Sync. (e.g. true)
  --job-title: string # The user’s job title. (e.g. CEO)
  --phone: string # The user’s phone number. (e.g. 6509241374)
  --address: string # The user’s address. (e.g. 900 Jefferson Ave, Redwood City, CA 94063)
  --space-amount: int # The user’s total available space in bytes. Set this to `-1` to indicate unlimited storage. (format: int64, e.g. 11345156112)
  --tracking-codes: list # Tracking codes allow an admin to generate reports from the admin console and assign an attribute to a specific group of users. This setting must be enabled for an enterprise before it can be used. — item shape: {type?: "tracking_code", name?: string, value?: string}
  --can-see-managed-users: string@bool-completer # Whether the user can see other enterprise users in their contact list. (e.g. true)
  --timezone: string # The user's timezone. (format: timezone, e.g. Africa/Bujumbura)
  --is-external-collab-restricted: string@bool-completer # Whether the user is allowed to collaborate with users outside their enterprise. (e.g. true)
  --is-exempt-from-device-limits: string@bool-completer # Whether to exempt the user from enterprise device limits. (e.g. true)
  --is-exempt-from-login-verification: string@bool-completer # Whether the user must use two-factor authentication. (e.g. true)
  --status: string@status-completer-3 # The user's account status. (e.g. active)
  --external-app-user-id: string # An external identifier for an app user, which can be used to look up the user. This can be used to tie user IDs from external identity providers to Box users. (e.g. my-user-1234)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let body = {name: $name, login: $login, is_platform_access_only: $is_platform_access_only, role: $role, language: $language, is_sync_enabled: $is_sync_enabled, job_title: $job_title, phone: $phone, address: $address, space_amount: $space_amount, tracking_codes: $tracking_codes, can_see_managed_users: $can_see_managed_users, timezone: $timezone, is_external_collab_restricted: $is_external_collab_restricted, is_exempt_from_device_limits: $is_exempt_from_device_limits, is_exempt_from_login_verification: $is_exempt_from_login_verification, status: $status, external_app_user_id: $external_app_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  user_ids: list # A list of user IDs. (e.g. [123456, 456789])
  user_logins: list # A list of user logins. (e.g. [user@sample.com, user2@sample.com])
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/terminate_sessions")
  let body = {user_ids: $user_ids, user_logins: $user_logins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user
#
# GET /users/{user_id}
# operationId: get_users_id
export def "users id-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /users/{user_id}
# operationId: put_users_id
# --tracking_codes item shape: {type?: "tracking_code", name?: string, value?: string}
# --notification_email shape: {email?: string}
export def "users id-by-user_id-1" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --enterprise: string # Set this to `null` to roll the user out of the enterprise and make them a free user. (nullable)
  --notify: string@bool-completer # Whether the user should receive an email when they are rolled out of an enterprise. (e.g. true)
  --name: string # The name of the user. (e.g. Aaron Levie)
  --login: string # The email address the user uses to log in  Note: If the target user's email is not confirmed, then the primary login address cannot be changed. (e.g. somename@box.com)
  --role: string@role-completer-2 # The user’s enterprise role. (e.g. user)
  --language: string # The language of the user, formatted in modified version of the [ISO 639-1](https://developer.box.com/guides/api-calls/language-codes) format. (e.g. en)
  --is-sync-enabled: string@bool-completer # Whether the user can use Box Sync. (e.g. true)
  --job-title: string # The user’s job title. (e.g. CEO)
  --phone: string # The user’s phone number. (e.g. 6509241374)
  --address: string # The user’s address. (e.g. 900 Jefferson Ave, Redwood City, CA 94063)
  --tracking-codes: list # Tracking codes allow an admin to generate reports from the admin console and assign an attribute to a specific group of users. This setting must be enabled for an enterprise before it can be used. — item shape: {type?: "tracking_code", name?: string, value?: string}
  --can-see-managed-users: string@bool-completer # Whether the user can see other enterprise users in their contact list. (e.g. true)
  --timezone: string # The user's timezone. (format: timezone, e.g. Africa/Bujumbura)
  --is-external-collab-restricted: string@bool-completer # Whether the user is allowed to collaborate with users outside their enterprise. (e.g. true)
  --is-exempt-from-device-limits: string@bool-completer # Whether to exempt the user from enterprise device limits. (e.g. true)
  --is-exempt-from-login-verification: string@bool-completer # Whether the user must use two-factor authentication. (e.g. true)
  --is-password-reset-required: string@bool-completer # Whether the user is required to reset their password. (e.g. true)
  --status: string@status-completer-3 # The user's account status. (e.g. active)
  --space-amount: int # The user’s total available space in bytes. Set this to `-1` to indicate unlimited storage. (format: int64, e.g. 11345156112)
  --notification-email: record # An alternate notification email address to which email notifications are sent. When it's confirmed, this will be the email address to which notifications are sent instead of to the primary email address.  Set this value to `null` to remove the notification email. (nullable) — shape: {email?: string}
  --external-app-user-id: string # An external identifier for an app user, which can be used to look up the user. This can be used to tie user IDs from external identity providers to Box users.  Note: In order to update this field, you need to request a token using the application that created the app user. (e.g. my-user-1234)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)" $qp)
  let body = {enterprise: $enterprise, notify: $notify, name: $name, login: $login, role: $role, language: $language, is_sync_enabled: $is_sync_enabled, job_title: $job_title, phone: $phone, address: $address, tracking_codes: $tracking_codes, can_see_managed_users: $can_see_managed_users, timezone: $timezone, is_external_collab_restricted: $is_external_collab_restricted, is_exempt_from_device_limits: $is_exempt_from_device_limits, is_exempt_from_login_verification: $is_exempt_from_login_verification, is_password_reset_required: $is_password_reset_required, status: $status, space_amount: $space_amount, notification_email: $notification_email, external_app_user_id: $external_app_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete user
#
# DELETE /users/{user_id}
# operationId: delete_users_id
export def "users id-by-user_id-2" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notify: string@bool-completer # Whether the user will receive email notification of the deletion. (e.g. true)
  --force: string@bool-completer # Specifies whether to delete the user even if they still own files. (e.g. true)
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user avatar
#
# GET /users/{user_id}/avatar
# operationId: get_users_id_avatar
export def "users-avatar avatar-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/avatar")
  let accept_val = ($accept | default "image/jpg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update user avatar
#
# POST /users/{user_id}/avatar
# operationId: post_users_id_avatar
export def "users-avatar avatar-by-user_id-1" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pic: string # The image file to be uploaded to Box. Accepted file extensions are `.jpg` or `.png`. The maximum file size is 1MB. (format: binary)
]: any -> record<pic_urls: record<small: string, large: string, preview: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/avatar")
  let body = {pic: $pic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete user avatar
#
# DELETE /users/{user_id}/avatar
# operationId: delete_users_id_avatar
export def "users-avatar avatar-by-user_id-2" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --notify: string@bool-completer # Determines if users should receive email notification for the action performed. (e.g. true)
  owned_by: record # The user who the folder will be transferred to. — shape: {id: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/folders/0" $qp)
  let body = {owned_by: $owned_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<total_count: int, entries: table<id: string, type: string, email: string, is_confirmed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/email_aliases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  email: string # The email address to add to the account as an alias.  Note: The domain of the email alias needs to be registered  to your enterprise. See the [domain verification guide](   https://support.box.com/hc/en-us/articles/4408619650579-Domain-Verification   ) for steps to add a new domain. (e.g. alias@example.com)
]: any -> record<id: string, type: string, email: string, is_confirmed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/email_aliases")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/email_aliases/($email_alias_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user invite
#
# POST /invites
# operationId: post_invites
# --enterprise shape: {id: string}
# --actionable_by shape: {login?: string}
export def "invites invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  enterprise: record # The enterprise to invite the user to. — shape: {id: string}
  actionable_by: record # The user to invite. — shape: {login?: string}
]: any -> record<id: string, type: string, invited_to: record<id: string, type: string, name: string>, actionable_by: record, invited_by: record, status: string, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/invites" $qp)
  let body = {enterprise: $enterprise, actionable_by: $actionable_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<id: string, type: string, invited_to: record<id: string, type: string, name: string>, actionable_by: record, invited_by: record, status: string, created_at: string, modified_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/invites/($invite_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List groups for enterprise
#
# GET /groups
# operationId: get_groups
export def "groups groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter-term: string # Limits the results to only groups whose `name` starts with the search term. (e.g. Engineering)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_term" $filter_term "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create group
#
# POST /groups
# operationId: post_groups
export def "groups groups-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  name: string # The name of the new group to be created. This name must be unique within the enterprise. (e.g. Customer Support)
  --provenance: string # Keeps track of which external source this group is coming, for example `Active Directory`, or `Okta`.  Setting this will also prevent Box admins from editing the group name and its members directly via the Box web application.  This is desirable for one-way syncing of groups. (e.g. Active Directory)
  --external-sync-identifier: string # An arbitrary identifier that can be used by external group sync tools to link this Box Group to an external group.  Example values of this field could be an **Active Directory Object ID** or a **Google Group ID**.  We recommend you use of this field in order to avoid issues when group names are updated in either Box or external systems. (e.g. AD:123456)
  --description: string # A human readable description of the group. (e.g. "Customer Support Group - as imported from Active Directory")
  --invitability-level: string@invitability-level-completer # Specifies who can invite the group to collaborate on folders.  When set to `admins_only` the enterprise admin, co-admins, and the group's admin can invite the group.  When set to `admins_and_members` all the admins listed above and group members can invite the group.  When set to `all_managed_users` all managed users in the enterprise can invite the group. (e.g. admins_only)
  --member-viewability-level: string@member-viewability-level-completer # Specifies who can see the members of the group.  * `admins_only` - the enterprise admin, co-admins, group's   group admin. * `admins_and_members` - all admins and group members. * `all_managed_users` - all managed users in the   enterprise. (e.g. admins_only)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let body = {name: $name, provenance: $provenance, external_sync_identifier: $external_sync_identifier, description: $description, invitability_level: $invitability_level, member_viewability_level: $member_viewability_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  group_ids: list # A list of group IDs. (e.g. [123456, 456789])
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/terminate_sessions")
  let body = {group_ids: $group_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get group
#
# GET /groups/{group_id}
# operationId: get_groups_id
export def "groups id-by-group_id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update group
#
# PUT /groups/{group_id}
# operationId: put_groups_id
export def "groups id-by-group_id-1" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # The name of the new group to be created. Must be unique within the enterprise. (e.g. Customer Support)
  --provenance: string # Keeps track of which external source this group is coming, for example `Active Directory`, or `Okta`.  Setting this will also prevent Box admins from editing the group name and its members directly via the Box web application.  This is desirable for one-way syncing of groups. (e.g. Active Directory)
  --external-sync-identifier: string # An arbitrary identifier that can be used by external group sync tools to link this Box Group to an external group.  Example values of this field could be an **Active Directory Object ID** or a **Google Group ID**.  We recommend you use of this field in order to avoid issues when group names are updated in either Box or external systems. (e.g. AD:123456)
  --description: string # A human readable description of the group. (e.g. "Customer Support Group - as imported from Active Directory")
  --invitability-level: string@invitability-level-completer # Specifies who can invite the group to collaborate on folders.  When set to `admins_only` the enterprise admin, co-admins, and the group's admin can invite the group.  When set to `admins_and_members` all the admins listed above and group members can invite the group.  When set to `all_managed_users` all managed users in the enterprise can invite the group. (e.g. admins_only)
  --member-viewability-level: string@member-viewability-level-completer # Specifies who can see the members of the group.  * `admins_only` - the enterprise admin, co-admins, group's   group admin. * `admins_and_members` - all admins and group members. * `all_managed_users` - all managed users in the   enterprise. (e.g. admins_only)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)" $qp)
  let body = {name: $name, provenance: $provenance, external_sync_identifier: $external_sync_identifier, description: $description, invitability_level: $invitability_level, member_viewability_level: $member_viewability_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove group
#
# DELETE /groups/{group_id}
# operationId: delete_groups_id
export def "groups id-by-group_id-2" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/collaborations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add user to group
#
# POST /group_memberships
# operationId: post_group_memberships
# --user shape: {id: string}
# --group shape: {id: string}
export def "group-memberships memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  user: record # The user to add to the group. — shape: {id: string}
  group: record # The group to add the user to. — shape: {id: string}
  --role: string@role-completer-3 # The role of the user in the group. (e.g. member)
  --configurable-permissions: record # Custom configuration for the permissions an admin if a group will receive. This option has no effect on members with a role of `member`.  Setting these permissions overwrites the default access levels of an admin.  Specifying a value of `null` for this object will disable all configurable permissions. Specifying permissions will set them accordingly, omitted permissions will be enabled by default. (nullable, e.g. {can_run_reports: true})
]: any -> record<id: string, type: string, user: record, group: record, role: string, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/group_memberships" $qp)
  let body = {user: $user, group: $group, role: $role, configurable_permissions: $configurable_permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get group membership
#
# GET /group_memberships/{group_membership_id}
# operationId: get_group_memberships_id
export def "group-memberships id-by-group_membership_id" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<id: string, type: string, user: record, group: record, role: string, created_at: string, modified_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/group_memberships/($group_membership_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update group membership
#
# PUT /group_memberships/{group_membership_id}
# operationId: put_group_memberships_id
export def "group-memberships id-by-group_membership_id-1" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --role: string@role-completer-3 # The role of the user in the group. (e.g. member)
  --configurable-permissions: record # Custom configuration for the permissions an admin if a group will receive. This option has no effect on members with a role of `member`.  Setting these permissions overwrites the default access levels of an admin.  Specifying a value of `null` for this object will disable all configurable permissions. Specifying permissions will set them accordingly, omitted permissions will be enabled by default. (nullable, e.g. {can_run_reports: true})
]: any -> record<id: string, type: string, user: record, group: record, role: string, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/group_memberships/($group_membership_id)" $qp)
  let body = {role: $role, configurable_permissions: $configurable_permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove user from group
#
# DELETE /group_memberships/{group_membership_id}
# operationId: delete_group_memberships_id
export def "group-memberships id-by-group_membership_id-2" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group_memberships/($group_membership_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all webhooks
#
# GET /webhooks
# operationId: get_webhooks
export def "webhooks webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /webhooks
# operationId: post_webhooks
# --target shape: {id?: string, type?: "file"|"folder"}
export def "webhooks webhooks-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  target: record # The item that will trigger the webhook. — shape: {id?: string, type?: "file"|"folder"}
  address: string # The URL that is notified by this webhook. (e.g. https://example.com/webhooks)
  triggers: list # An array of event names that this webhook is to be triggered for. (e.g. [FILE.UPLOADED])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {target: $target, address: $address, triggers: $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get webhook
#
# GET /webhooks/{webhook_id}
# operationId: get_webhooks_id
export def "webhooks id-by-webhook_id" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /webhooks/{webhook_id}
# operationId: put_webhooks_id
# --target shape: {id?: string, type?: "file"|"folder"}
export def "webhooks id-by-webhook_id-1" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target: record # The item that will trigger the webhook. — shape: {id?: string, type?: "file"|"folder"}
  --address: string # The URL that is notified by this webhook. (e.g. https://example.com/webhooks)
  --triggers: list # An array of event names that this webhook is to be triggered for. (e.g. [FILE.UPLOADED])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let body = {target: $target, address: $address, triggers: $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove webhook
#
# DELETE /webhooks/{webhook_id}
# operationId: delete_webhooks_id
export def "webhooks id-by-webhook_id-2" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update all Box Skill cards on file
#
# PUT /skill_invocations/{skill_id}
# operationId: put_skill_invocations_id
# --metadata shape: {cards?: list}
# --file shape: {type?: "file", id?: string}
# --file_version shape: {type?: "file_version", id?: string}
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
  status: string@status-completer-4 # Defines the status of this invocation. Set this to `success` when setting Skill cards. (e.g. success)
  metadata: record # The metadata to set for this skill. This is a list of Box Skills cards. These cards will overwrite any existing Box skill cards on the file. — shape: {cards?: list}
  file: record # The file to assign the cards to. — shape: {type?: "file", id?: string}
  --file-version: record # The optional file version to assign the cards to. — shape: {type?: "file_version", id?: string}
  --usage: record # A descriptor that defines what items are affected by this call.  Set this to the default values when setting a card to a `success` state, and leave it out in most other situations. — shape: {unit?: string, value?: float}
]: any -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skill_invocations/($skill_id)")
  let body = {status: $status, metadata: $metadata, file: $file, file_version: $file_version, usage: $usage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get events long poll endpoint
#
# OPTIONS /events
# operationId: options_events
export def "events events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user and enterprise events
#
# GET /events
# operationId: get_events
export def "events events-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream-type: string@stream-type-completer # Defines the type of events that are returned  * `all` returns everything for a user and is the default * `changes` returns events that may cause file tree changes   such as file updates or collaborations. * `sync` is similar to `changes` but only applies to synced folders * `admin_logs` returns all events for an entire enterprise and   requires the user making the API call to have admin permissions. This   stream type is for programmatically pulling from a 1 year history of   events across all users within the enterprise and within a   `created_after` and `created_before` time frame. The complete history   of events will be returned in chronological order based on the event   time, but latency will be much higher than `admin_logs_streaming`. * `admin_logs_streaming` returns all events for an entire enterprise and   requires the user making the API call to have admin permissions. This   stream type is for polling for recent events across all users within   the enterprise. Latency will be much lower than `admin_logs`, but   events will not be returned in chronological order and may   contain duplicates. (default: all, e.g. all)
  --stream-position: string # The location in the event stream to start receiving events from.  * `now` will return an empty list events and the latest stream position for initialization. * `0` or `null` will return all events. (e.g. 1348790499819)
  --limit: int # Limits the number of events returned.  Note: Sometimes, the events less than the limit requested can be returned even when there may be more events remaining. This is primarily done in the case where a number of events have already been retrieved and these retrieved events are returned rather than delaying for an unknown amount of time to see if there are any more results. (format: int64, default: 100, e.g. 50)
  --event-type: list # A comma-separated list of events to filter by. This can only be used when requesting the events with a `stream_type` of `admin_logs` or `adming_logs_streaming`. For any other `stream_type` this value will be ignored. (e.g. [ACCESS_GRANTED])
  --created-after: string # The lower bound date and time to return events for. This can only be used when requesting the events with a `stream_type` of `admin_logs`. For any other `stream_type` this value will be ignored. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --created-before: string # The upper bound date and time to return events for. This can only be used when requesting the events with a `stream_type` of `admin_logs`. For any other `stream_type` this value will be ignored. (format: date-time, e.g. 2013-12-12T10:53:43-08:00)
]: nothing -> record<chunk_size: int, next_stream_position: any, entries: table<type: string, created_at: string, recorded_at: string, event_id: string, created_by: record, event_type: record, session_id: string, source: record, additional_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream_type" $stream_type "scalar") (serialize-qp "stream_position" $stream_position "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "event_type" $event_type "csv") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all collections
#
# GET /collections
# operationId: get_collections
export def "collections collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response.  Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get collection by ID
#
# GET /collections/{collection_id}
# operationId: get_collections_id
export def "collections id" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, name: string, collection_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recent_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --policy-name: string # Filters results by a case sensitive prefix of the name of retention policies. (e.g. Sales Policy)
  --policy-type: string@policy-type-completer # Filters results by the type of retention policy. (e.g. finite)
  --created-by-user-id: string # Filters results by the ID of the user who created policy. (e.g. 21312321)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_name" $policy_name "scalar") (serialize-qp "policy_type" $policy_type "scalar") (serialize-qp "created_by_user_id" $created_by_user_id "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/retention_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create retention policy
#
# POST /retention_policies
# operationId: post_retention_policies
# --custom_notification_recipients item shape: {id: string, type: "user", name?: string, login?: string}
export def "retention-policies policies-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  policy_name: string # The name for the retention policy. (e.g. Some Policy Name)
  --description: string # The additional text description of the retention policy. (e.g. Policy to retain all reports for at least one month)
  policy_type: string@policy-type-completer # The type of the retention policy. A retention policy type can either be `finite`, where a specific amount of time to retain the content is known upfront, or `indefinite`, where the amount of time to retain the content is still unknown. (e.g. finite)
  disposition_action: string@disposition-action-completer # The disposition action of the retention policy. `permanently_delete` deletes the content retained by the policy permanently. `remove_retention` lifts retention policy from the content, allowing it to be deleted by users once the retention policy has expired. (e.g. permanently_delete)
  --retention-length: any # The length of the retention policy. This value specifies the duration in days that the retention policy will be active for after being assigned to content.  If the policy has a `policy_type` of `indefinite`, the `retention_length` will also be `indefinite`. (e.g. 365)
  --retention-type: string@retention-type-completer # Specifies the retention type:  * `modifiable`: You can modify the retention policy. For example, you can add or remove folders, shorten or lengthen the policy duration, or delete the assignment. Use this type if your retention policy is not related to any regulatory purposes.  * `non_modifiable`: You can modify the retention policy only in a limited way: add a folder, lengthen the duration, retire the policy, change the disposition action or notification settings. You cannot perform other actions, such as deleting the assignment or shortening the policy duration. Use this type to ensure compliance with regulatory retention policies. (e.g. modifiable)
  --can-owner-extend-retention: string@bool-completer # Whether the owner of a file will be allowed to extend the retention. (e.g. true)
  --max-extension-length: any # The maximum extension length of the retention date. This value specifies the duration in days for which the retention date of the file under policy can be extended. It can be specified only for the 'finite' policy type where the disposition action is 'permanently delete', otherwise the server will return status 400. If this value is 'none', it won't be possible to extend the retention. (e.g. 365)
  --are-owners-notified: string@bool-completer # Whether owner and co-owners of a file are notified when the policy nears expiration. (e.g. true)
  --custom-notification-recipients: list # A list of users notified when the retention policy duration is about to end. — item shape: {id: string, type: "user", name?: string, login?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retention_policies")
  let body = {policy_name: $policy_name, description: $description, policy_type: $policy_type, disposition_action: $disposition_action, retention_length: $retention_length, retention_type: $retention_type, can_owner_extend_retention: $can_owner_extend_retention, max_extension_length: $max_extension_length, are_owners_notified: $are_owners_notified, custom_notification_recipients: $custom_notification_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get retention policy
#
# GET /retention_policies/{retention_policy_id}
# operationId: get_retention_policies_id
export def "retention-policies id-by-retention_policy_id" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/retention_policies/($retention_policy_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update retention policy
#
# PUT /retention_policies/{retention_policy_id}
# operationId: put_retention_policies_id
# --custom_notification_recipients item shape: {id: string, type: "user"}
export def "retention-policies id-by-retention_policy_id-1" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policy-name: string # The name for the retention policy. (nullable, e.g. Some Policy Name)
  --description: string # The additional text description of the retention policy. (nullable, e.g. Policy to retain all reports for at least one month)
  --disposition-action: any # The disposition action of the retention policy. This action can be `permanently_delete`, which will cause the content retained by the policy to be permanently deleted, or `remove_retention`, which will lift the retention policy from the content, allowing it to be deleted by users, once the retention policy has expired. You can use `null` if you don't want to change `disposition_action`. (e.g. permanently_delete)
  --retention-type: string # Specifies the retention type:  * `modifiable`: You can modify the retention policy. For example, you can add or remove folders, shorten or lengthen the policy duration, or delete the assignment. Use this type if your retention policy is not related to any regulatory purposes. * `non-modifiable`: You can modify the retention policy only in a limited way: add a folder, lengthen the duration, retire the policy, change the disposition action or notification settings. You cannot perform other actions, such as deleting the assignment or shortening the policy duration. Use this type to ensure compliance with regulatory retention policies.  When updating a retention policy, you can use `non-modifiable` type only. You can convert a `modifiable` policy to `non-modifiable`, but not the other way around. (nullable, e.g. non-modifiable)
  --retention-length: any # The length of the retention policy. This value specifies the duration in days that the retention policy will be active for after being assigned to content.  If the policy has a `policy_type` of `indefinite`, the `retention_length` will also be `indefinite`. (e.g. 365)
  --status: string # Used to retire a retention policy.  If not retiring a policy, do not include this parameter or set it to `null`. (nullable, e.g. retired)
  --can-owner-extend-retention: string@bool-completer # Determines if the owner of items under the policy can extend the retention when the original retention duration is about to end. (nullable, e.g. false)
  --max-extension-length: any # The maximum extension length of the retention date. This value specifies the duration in days for which the retention date of the file under policy can be extended. It can be specified only for the 'finite' policy type where the disposition action is 'permanently delete', otherwise the server will return status 400. If this value is 'none', it won't be possible to extend the retention. (e.g. 365)
  --are-owners-notified: string@bool-completer # Determines if owners and co-owners of items under the policy are notified when the retention duration is about to end. (nullable, e.g. false)
  --custom-notification-recipients: list # A list of users notified when the retention duration is about to end. (nullable) — item shape: {id: string, type: "user"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retention_policies/($retention_policy_id)")
  let body = {policy_name: $policy_name, description: $description, disposition_action: $disposition_action, retention_type: $retention_type, retention_length: $retention_length, status: $status, can_owner_extend_retention: $can_owner_extend_retention, max_extension_length: $max_extension_length, are_owners_notified: $are_owners_notified, custom_notification_recipients: $custom_notification_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete retention policy
#
# DELETE /retention_policies/{retention_policy_id}
# operationId: delete_retention_policies_id
export def "retention-policies id-by-retention_policy_id-2" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retention_policies/($retention_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --type: string@type-completer-2 # The type of the retention policy assignment to retrieve. (e.g. metadata_template)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retention_policies/($retention_policy_id)/assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign retention policy
#
# POST /retention_policy_assignments
# operationId: post_retention_policy_assignments
# --assign_to shape: {type: "enterprise"|"folder"|"metadata_template", id?: string}
# --filter_fields item shape: {field?: string, value?: string}
export def "retention-policy-assignments assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  policy_id: string # The ID of the retention policy to assign. (e.g. 173463)
  assign_to: record # The item to assign the policy to. — shape: {type: "enterprise"|"folder"|"metadata_template", id?: string}
  --filter-fields: list # If the `assign_to` type is `metadata_template`, then optionally add the `filter_fields` parameter which will require an array of objects with a field entry and a value entry. Currently only one object of `field` and `value` is supported. — item shape: {field?: string, value?: string}
  --start-date-field: string # The date the retention policy assignment begins.  If the `assigned_to` type is `metadata_template`, this field can be a date field's metadata attribute key id. (e.g. upload_date)
]: any -> record<id: string, type: string, retention_policy: record, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, assigned_by: record, assigned_at: string, start_date_field: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retention_policy_assignments")
  let body = {policy_id: $policy_id, assign_to: $assign_to, filter_fields: $filter_fields, start_date_field: $start_date_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get retention policy assignment
#
# GET /retention_policy_assignments/{retention_policy_assignment_id}
# operationId: get_retention_policy_assignments_id
export def "retention-policy-assignments id-by-retention_policy_assignment_id" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record<id: string, type: string, retention_policy: record, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, assigned_by: record, assigned_at: string, start_date_field: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/retention_policy_assignments/($retention_policy_assignment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove retention policy assignment
#
# DELETE /retention_policy_assignments/{retention_policy_assignment_id}
# operationId: delete_retention_policy_assignments_id
export def "retention-policy-assignments id-by-retention_policy_assignment_id-1" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retention_policy_assignments/($retention_policy_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retention_policy_assignments/($retention_policy_assignment_id)/files_under_retention" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retention_policy_assignments/($retention_policy_assignment_id)/file_versions_under_retention" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --policy-name: string # Limits results to policies for which the names start with this search term. This is a case-insensitive prefix. (e.g. Sales Policy)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_name" $policy_name "scalar") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/legal_hold_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  policy_name: string # The name of the policy. (e.g. Sales Policy)
  --description: string # A description for the policy. (e.g. A custom policy for the sales team)
  --filter-started-at: string # The filter start date.  When this policy is applied using a `custodian` legal hold assignments, it will only apply to file versions created or uploaded inside of the date range. Other assignment types, such as folders and files, will ignore the date filter.  Required if `is_ongoing` is set to `false`. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --filter-ended-at: string # The filter end date.  When this policy is applied using a `custodian` legal hold assignments, it will only apply to file versions created or uploaded inside of the date range. Other assignment types, such as folders and files, will ignore the date filter.  Required if `is_ongoing` is set to `false`. (format: date-time, e.g. 2012-12-18T10:53:43-08:00)
  --is-ongoing: string@bool-completer # Whether new assignments under this policy should continue applying to files even after initialization.  When this policy is applied using a legal hold assignment, it will continue applying the policy to any new file versions even after it has been applied.  For example, if a legal hold assignment is placed on a user today, and that user uploads a file tomorrow, that file will get held. This will continue until the policy is retired.  Required if no filter dates are set. (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legal_hold_policies")
  let body = {policy_name: $policy_name, description: $description, filter_started_at: $filter_started_at, filter_ended_at: $filter_ended_at, is_ongoing: $is_ongoing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get legal hold policy
#
# GET /legal_hold_policies/{legal_hold_policy_id}
# operationId: get_legal_hold_policies_id
export def "legal-hold-policies id-by-legal_hold_policy_id" [
  legal_hold_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_hold_policies/($legal_hold_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update legal hold policy
#
# PUT /legal_hold_policies/{legal_hold_policy_id}
# operationId: put_legal_hold_policies_id
export def "legal-hold-policies id-by-legal_hold_policy_id-1" [
  legal_hold_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policy-name: string # The name of the policy. (e.g. Sales Policy)
  --description: string # A description for the policy. (e.g. A custom policy for the sales team)
  --release-notes: string # Notes around why the policy was released. (e.g. Required for GDPR)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_hold_policies/($legal_hold_policy_id)")
  let body = {policy_name: $policy_name, description: $description, release_notes: $release_notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove legal hold policy
#
# DELETE /legal_hold_policies/{legal_hold_policy_id}
# operationId: delete_legal_hold_policies_id
export def "legal-hold-policies id-by-legal_hold_policy_id-2" [
  legal_hold_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_hold_policies/($legal_hold_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --policy-id: string # The ID of the legal hold policy. (e.g. 324432)
  --assign-to-type: string@assign-to-type-completer # Filters the results by the type of item the policy was applied to. (e.g. file)
  --assign-to-id: string # Filters the results by the ID of item the policy was applied to. (e.g. 1234323)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "assign_to_type" $assign_to_type "scalar") (serialize-qp "assign_to_id" $assign_to_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/legal_hold_policy_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign legal hold policy
#
# POST /legal_hold_policy_assignments
# operationId: post_legal_hold_policy_assignments
# --assign_to shape: {type: "file"|"file_version"|"folder"|"user"|"ownership"|"interactions", id: string}
export def "legal-hold-policy-assignments assignments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  policy_id: string # The ID of the policy to assign. (e.g. 123244)
  assign_to: record # The item to assign the policy to. — shape: {type: "file"|"file_version"|"folder"|"user"|"ownership"|"interactions", id: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legal_hold_policy_assignments")
  let body = {policy_id: $policy_id, assign_to: $assign_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get legal hold policy assignment
#
# GET /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}
# operationId: get_legal_hold_policy_assignments_id
export def "legal-hold-policy-assignments id-by-legal_hold_policy_assignment_id" [
  legal_hold_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_hold_policy_assignments/($legal_hold_policy_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unassign legal hold policy
#
# DELETE /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}
# operationId: delete_legal_hold_policy_assignments_id
export def "legal-hold-policy-assignments id-by-legal_hold_policy_assignment_id-1" [
  legal_hold_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legal_hold_policy_assignments/($legal_hold_policy_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files with current file versions for legal hold policy assignment
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/legal_hold_policy_assignments/($legal_hold_policy_assignment_id)/files_on_hold" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/legal_hold_policy_assignments/($legal_hold_policy_assignment_id)/file_versions_on_hold" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, type: string, file_version: record, file: record, applied_at: string, disposition_at: string, winning_retention_policy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file_version_retentions/($file_version_retention_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, type: string, file_version: record, file: record, legal_hold_policy_assignments: list<record>, deleted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/file_version_legal_holds/($file_version_legal_hold_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, type: string, enterprise: record<id: string, type: string>, status: string, created_at: string, created_by: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barriers/($shield_information_barrier_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  id: string # The ID of the shield information barrier. (e.g. 1910967)
  status: string@status-completer-5 # The desired status for the shield information barrier. (e.g. pending)
]: any -> record<id: string, type: string, enterprise: record<id: string, type: string>, status: string, created_at: string, created_by: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barriers/change_status")
  let body = {id: $id, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barriers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  enterprise: any # The `type` and `id` of enterprise this barrier is under.
]: any -> record<id: string, type: string, enterprise: record<id: string, type: string>, status: string, created_at: string, created_by: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barriers")
  let body = {enterprise: $enterprise} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --shield-information-barrier-id: string # The ID of the shield information barrier. (e.g. 1910967)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_id" $shield_information_barrier_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --shield-information-barrier: record # A base representation of a shield information barrier object. — shape: {id?: string, type?: "shield_information_barrier"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_reports")
  let body = {shield_information_barrier: $shield_information_barrier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_reports/($shield_information_barrier_report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shield information barrier segment with specified ID
#
# GET /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# operationId: get_shield_information_barrier_segments_id
export def "shield-information-barrier-segments id-by-shield_information_barrier_segment_id" [
  shield_information_barrier_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, shield_information_barrier: record<id: string, type: string>, name: string, description: string, created_at: string, created_by: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_segments/($shield_information_barrier_segment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete shield information barrier segment
#
# DELETE /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# operationId: delete_shield_information_barrier_segments_id
export def "shield-information-barrier-segments id-by-shield_information_barrier_segment_id-1" [
  shield_information_barrier_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_segments/($shield_information_barrier_segment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --name: string # The updated name for the shield information barrier segment. (e.g. Investment Banking)
  --description: string # The updated description for the shield information barrier segment. (nullable, e.g. 'Corporate division that engages in advisory_based financial transactions on behalf of individuals, corporations, and governments.')
]: any -> record<id: string, type: string, shield_information_barrier: record<id: string, type: string>, name: string, description: string, created_at: string, created_by: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_segments/($shield_information_barrier_segment_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --shield-information-barrier-id: string # The ID of the shield information barrier. (e.g. 1910967)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_id" $shield_information_barrier_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  shield_information_barrier: record # A base representation of a shield information barrier object. — shape: {id?: string, type?: "shield_information_barrier"}
  name: string # Name of the shield information barrier segment. (e.g. Investment Banking)
  --description: string # Description of the shield information barrier segment. (e.g. 'Corporate division that engages in  advisory_based financial transactions on behalf of individuals, corporations, and governments.')
]: any -> record<id: string, type: string, shield_information_barrier: record<id: string, type: string>, name: string, description: string, created_at: string, created_by: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_segments")
  let body = {shield_information_barrier: $shield_information_barrier, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get shield information barrier segment member by ID
#
# GET /shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}
# operationId: get_shield_information_barrier_segment_members_id
export def "shield-information-barrier-segment-members id-by-shield_information_barrier_segment_member_id" [
  shield_information_barrier_segment_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_segment_members/($shield_information_barrier_segment_member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete shield information barrier segment member by ID
#
# DELETE /shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}
# operationId: delete_shield_information_barrier_segment_members_id
export def "shield-information-barrier-segment-members id-by-shield_information_barrier_segment_member_id-1" [
  shield_information_barrier_segment_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_segment_members/($shield_information_barrier_segment_member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --shield-information-barrier-segment-id: string # The ID of the shield information barrier segment. (e.g. 3423)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_segment_id" $shield_information_barrier_segment_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_segment_members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --type: string@type-completer-3 # A type of the shield barrier segment member. (e.g. shield_information_barrier_segment_member)
  --shield-information-barrier: record # A base representation of a shield information barrier object. — shape: {id?: string, type?: "shield_information_barrier"}
  shield_information_barrier_segment: record # The `type` and `id` of the requested shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  user: any # User to which restriction will be applied.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_segment_members")
  let body = {type: $type, shield_information_barrier: $shield_information_barrier, shield_information_barrier_segment: $shield_information_barrier_segment, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get shield information barrier segment restriction by ID
#
# GET /shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}
# operationId: get_shield_information_barrier_segment_restrictions_id
export def "shield-information-barrier-segment-restrictions id-by-shield_information_barrier_segment_restriction_id" [
  shield_information_barrier_segment_restriction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_segment_restrictions/($shield_information_barrier_segment_restriction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete shield information barrier segment restriction by ID
#
# DELETE /shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}
# operationId: delete_shield_information_barrier_segment_restrictions_id
export def "shield-information-barrier-segment-restrictions id-by-shield_information_barrier_segment_restriction_id-1" [
  shield_information_barrier_segment_restriction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shield_information_barrier_segment_restrictions/($shield_information_barrier_segment_restriction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --shield-information-barrier-segment-id: string # The ID of the shield information barrier segment. (e.g. 3423)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shield_information_barrier_segment_id" $shield_information_barrier_segment_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shield_information_barrier_segment_restrictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shield information barrier segment restriction
#
# POST /shield_information_barrier_segment_restrictions
# operationId: post_shield_information_barrier_segment_restrictions
# --shield_information_barrier shape: {id?: string, type?: "shield_information_barrier"}
# --shield_information_barrier_segment shape: {id?: string, type?: "shield_information_barrier_segment"}
# --restricted_segment shape: {id?: string, type?: "shield_information_barrier_segment"}
export def "shield-information-barrier-segment-restrictions restrictions-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-4 # The type of the shield barrier segment restriction for this member. (e.g. shield_information_barrier_segment_restriction)
  --shield-information-barrier: record # A base representation of a shield information barrier object. — shape: {id?: string, type?: "shield_information_barrier"}
  shield_information_barrier_segment: record # The `type` and `id` of the requested shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  restricted_segment: record # The `type` and `id` of the restricted shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shield_information_barrier_segment_restrictions")
  let body = {type: $type, shield_information_barrier: $shield_information_barrier, shield_information_barrier_segment: $shield_information_barrier_segment, restricted_segment: $restricted_segment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get device pin
#
# GET /device_pinners/{device_pinner_id}
# operationId: get_device_pinners_id
export def "device-pinners id-by-device_pinner_id" [
  device_pinner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, owned_by: record, product_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/device_pinners/($device_pinner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove device pin
#
# DELETE /device_pinners/{device_pinner_id}
# operationId: delete_device_pinners_id
export def "device-pinners id-by-device_pinner_id-1" [
  device_pinner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/device_pinners/($device_pinner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --direction: string@direction-completer # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
]: nothing -> record<entries: table<id: string, type: string, owned_by: record, product_name: string>, limit: int, next_marker: int, order: table<by: string, direction: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/enterprises/($enterprise_id)/device_pinners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --tos-type: string@tos-type-completer # Limits the results to the terms of service of the given type. (e.g. managed)
]: nothing -> record<total_count: int, entries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tos_type" $tos_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/terms_of_services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  status: string@status-completer-6 # Whether this terms of service is active. (e.g. enabled)
  --tos-type: string@tos-type-completer # The type of user to set the terms of service for. (e.g. managed)
  text: string # The terms of service text to display to users.  The text can be set to empty if the `status` is set to `disabled`. (e.g. By collaborating on this file you are accepting...)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/terms_of_services")
  let body = {status: $status, tos_type: $tos_type, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terms_of_services/($terms_of_service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  status: string@status-completer-6 # Whether this terms of service is active. (e.g. enabled)
  text: string # The terms of service text to display to users.  The text can be set to empty if the `status` is set to `disabled`. (e.g. By collaborating on this file you are accepting...)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terms_of_services/($terms_of_service_id)")
  let body = {status: $status, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --tos-id: string # The ID of the terms of service. (e.g. 324234)
  --user-id: string # Limits results to the given user ID. (e.g. 123334)
]: nothing -> record<total_count: int, entries: table<id: string, type: string, tos: record, user: record, is_accepted: bool, created_at: string, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tos_id" $tos_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/terms_of_service_user_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create terms of service status for new user
#
# POST /terms_of_service_user_statuses
# operationId: post_terms_of_service_user_statuses
# --tos shape: {type: "terms_of_service", id: string}
# --user shape: {type: "user", id: string}
export def "terms-of-service-user-statuses statuses-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tos: record # The terms of service to set the status for. — shape: {type: "terms_of_service", id: string}
  user: record # The user to set the status for. — shape: {type: "user", id: string}
  --is-accepted: string@bool-completer # Whether the user has accepted the terms. (e.g. true)
]: any -> record<id: string, type: string, tos: record<id: string, type: string>, user: record, is_accepted: bool, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/terms_of_service_user_statuses")
  let body = {tos: $tos, user: $user, is_accepted: $is_accepted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --is-accepted: string@bool-completer # Whether the user has accepted the terms. (e.g. true)
]: any -> record<id: string, type: string, tos: record<id: string, type: string>, user: record, is_accepted: bool, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terms_of_service_user_statuses/($terms_of_service_user_status_id)")
  let body = {is_accepted: $is_accepted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaboration_whitelist_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  domain: string # The domain to add to the list of allowed domains. (e.g. example.com)
  direction: string@direction-completer-1 # The direction in which to allow collaborations. (e.g. inbound)
]: any -> record<id: string, type: string, domain: string, direction: string, enterprise: record<id: string, type: string, name: string>, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaboration_whitelist_entries")
  let body = {domain: $domain, direction: $direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get allowed collaboration domain
#
# GET /collaboration_whitelist_entries/{collaboration_whitelist_entry_id}
# operationId: get_collaboration_whitelist_entries_id
export def "collaboration-whitelist-entries id-by-collaboration_whitelist_entry_id" [
  collaboration_whitelist_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, domain: string, direction: string, enterprise: record<id: string, type: string, name: string>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaboration_whitelist_entries/($collaboration_whitelist_entry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove domain from list of allowed collaboration domains
#
# DELETE /collaboration_whitelist_entries/{collaboration_whitelist_entry_id}
# operationId: delete_collaboration_whitelist_entries_id
export def "collaboration-whitelist-entries id-by-collaboration_whitelist_entry_id-1" [
  collaboration_whitelist_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaboration_whitelist_entries/($collaboration_whitelist_entry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collaboration_whitelist_exempt_targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  user: record # The user to exempt. — shape: {id: string}
]: any -> record<id: string, type: string, enterprise: record<id: string, type: string, name: string>, user: record, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaboration_whitelist_exempt_targets")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user exempt from collaboration domain restrictions
#
# GET /collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}
# operationId: get_collaboration_whitelist_exempt_targets_id
export def "collaboration-whitelist-exempt-targets id-by-collaboration_whitelist_exempt_target_id" [
  collaboration_whitelist_exempt_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, enterprise: record<id: string, type: string, name: string>, user: record, created_at: string, modified_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaboration_whitelist_exempt_targets/($collaboration_whitelist_exempt_target_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove user from list of users exempt from domain restrictions
#
# DELETE /collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}
# operationId: delete_collaboration_whitelist_exempt_targets_id
export def "collaboration-whitelist-exempt-targets id-by-collaboration_whitelist_exempt_target_id-1" [
  collaboration_whitelist_exempt_target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collaboration_whitelist_exempt_targets/($collaboration_whitelist_exempt_target_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --qp-fields: list # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response.  Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storage_policies/($storage_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --resolved-for-type: string@resolved-for-type-completer # The target type to return assignments for. (e.g. user)
  --resolved-for-id: string # The ID of the user or enterprise to return assignments for. (e.g. 984322)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "resolved_for_type" $resolved_for_type "scalar") (serialize-qp "resolved_for_id" $resolved_for_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage_policy_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign storage policy
#
# POST /storage_policy_assignments
# operationId: post_storage_policy_assignments
# --storage_policy shape: {type: "storage_policy", id: string}
# --assigned_to shape: {type: "user"|"enterprise", id: string}
export def "storage-policy-assignments assignments-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  storage_policy: record # The storage policy to assign to the user or enterprise. — shape: {type: "storage_policy", id: string}
  assigned_to: record # The user or enterprise to assign the storage policy to. — shape: {type: "user"|"enterprise", id: string}
]: any -> record<id: string, type: string, storage_policy: record<id: string, type: string>, assigned_to: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storage_policy_assignments")
  let body = {storage_policy: $storage_policy, assigned_to: $assigned_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get storage policy assignment
#
# GET /storage_policy_assignments/{storage_policy_assignment_id}
# operationId: get_storage_policy_assignments_id
export def "storage-policy-assignments id-by-storage_policy_assignment_id" [
  storage_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, storage_policy: record<id: string, type: string>, assigned_to: record<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storage_policy_assignments/($storage_policy_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update storage policy assignment
#
# PUT /storage_policy_assignments/{storage_policy_assignment_id}
# operationId: put_storage_policy_assignments_id
# --storage_policy shape: {type: "storage_policy", id: string}
export def "storage-policy-assignments id-by-storage_policy_assignment_id-1" [
  storage_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  storage_policy: record # The storage policy to assign to the user or enterprise. — shape: {type: "storage_policy", id: string}
]: any -> record<id: string, type: string, storage_policy: record<id: string, type: string>, assigned_to: record<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storage_policy_assignments/($storage_policy_assignment_id)")
  let body = {storage_policy: $storage_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign storage policy
#
# DELETE /storage_policy_assignments/{storage_policy_assignment_id}
# operationId: delete_storage_policy_assignments_id
export def "storage-policy-assignments id-by-storage_policy_assignment_id-2" [
  storage_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storage_policy_assignments/($storage_policy_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create zip download
#
# POST /zip_downloads
# operationId: post_zip_downloads
# --items item shape: {type: "file"|"folder", id: string}
export def "zip-downloads downloads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # A list of items to add to the `zip` archive. These can be folders or files. — item shape: {type: "file"|"folder", id: string}
  --download-file-name: string # The optional name of the `zip` archive. This name will be appended by the `.zip` file extension, for example `January Financials.zip`. (e.g. January Financials)
]: any -> record<download_url: string, status_url: string, expires_at: string, name_conflicts: list<list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/zip_downloads")
  let body = {items: $items, download_file_name: $download_file_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dl.boxcloud.com/2.0")
  let full_url = (build-url $base $"/zip_downloads/($zip_download_id)/content")
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<total_file_count: int, downloaded_file_count: int, skipped_file_count: int, skipped_folder_count: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/zip_downloads/($zip_download_id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Box Sign request
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
  --reason: string # An optional reason for cancelling the sign request. (e.g. Project cancelled)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sign_requests/($sign_request_id)/cancel")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resend Box Sign request
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
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sign_requests/($sign_request_id)/resend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Box Sign request by ID
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sign_requests/($sign_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Box Sign requests
#
# GET /sign_requests
# operationId: get_sign_requests
export def "sign-requests requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --senders: list # A list of sender emails to filter the signature requests by sender. If provided, `shared_requests` must be set to `true`. (e.g. [sender1@boxdemo.com, sender2@boxdemo.com])
  --shared-requests: string@bool-completer # If set to `true`, only includes requests that user is not an owner, but user is a collaborator. Collaborator access is determined by the user access level of the sign files of the request. Default is `false`. Must be set to `true` if `senders` are provided. (default: false, e.g. true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "senders" $senders "multi") (serialize-qp "shared_requests" $shared_requests "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sign_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Box Sign request
#
# POST /sign_requests
# operationId: post_sign_requests
# --prefill_tags item shape: {document_tag_id?: string, text_value?: string, checkbox_value?: bool, date_value?: string}
# --source_files item shape: {id: string, etag?: string, type: "file"}
# --signers item shape: {email?: string, role?: "signer"|"approver"|"final_copy_reader", is_in_person?: bool, order?: int, embed_url_external_user_id?: string, redirect_url?: string, declined_redirect_url?: string, login_required?: bool, verification_phone_number?: string, password?: string, signer_group_id?: string, suppress_notifications?: bool, language?: string}
export def "sign-requests requests-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-document-preparation-needed: string@bool-completer # Indicates if the sender should receive a `prepare_url` in the response to complete document preparation using the UI. (e.g. true)
  --redirect-url: string # When specified, the signature request will be redirected to this url when a document is signed. (nullable, e.g. https://www.example.com)
  --declined-redirect-url: string # The uri that a signer will be redirected to after declining to sign a document. (nullable, e.g. https://declined-redirect.com)
  --are-text-signatures-enabled: string@bool-completer # Disables the usage of signatures generated by typing (text). (default: true, e.g. true)
  --email-subject: string # Subject of sign request email. This is cleaned by sign request. If this field is not passed, a default subject will be used. (nullable, e.g. Sign Request from Acme)
  --email-message: string # Message to include in sign request email. The field is cleaned through sanitization of specific characters. However, some html tags are allowed. Links included in the message are also converted to hyperlinks in the email. The message may contain the following html tags including `a`, `abbr`, `acronym`, `b`, `blockquote`, `code`, `em`, `i`, `ul`, `li`, `ol`, and `strong`. Be aware that when the text to html ratio is too high, the email may end up in spam filters. Custom styles on these tags are not allowed. If this field is not passed, a default message will be used. (nullable, e.g. Hello! Please sign the document below)
  --are-reminders-enabled: string@bool-completer # Reminds signers to sign a document on day 3, 8, 13 and 18. Reminders are only sent to outstanding signers. (e.g. true)
  --name: string # Name of the signature request. (e.g. name)
  --prefill-tags: list # When a document contains sign-related tags in the content, you can prefill them using this `prefill_tags` by referencing the 'id' of the tag as the `external_id` field of the prefill tag. — item shape: {document_tag_id?: string, text_value?: string, checkbox_value?: bool, date_value?: string}
  --days-valid: int # Set the number of days after which the created signature request will automatically expire if not completed. By default, we do not apply any expiration date on signature requests, and the signature request does not expire. (nullable, e.g. 2)
  --external-id: string # This can be used to reference an ID in an external system that the sign request is related to. (nullable, e.g. 123)
  --template-id: string # When a signature request is created from a template this field will indicate the id of that template. (nullable, e.g. 123075213-af2c8822-3ef2-4952-8557-52d69c2fe9cb)
  --external-system-name: string # Used as an optional system name to appear in the signature log next to the signers who have been assigned the `embed_url_external_id`. (nullable, e.g. Box)
  --source-files: list # List of files to create a signing document from. This is currently limited to ten files. Only the ID and type fields are required for each file. (nullable) — item shape: {id: string, etag?: string, type: "file"}
  --signature-color: string@signature-color-completer # Force a specific color for the signature (blue, black, or red). (nullable, e.g. blue)
  signers: list # Array of signers for the signature request. 35 is the max number of signers permitted.  **Note**: It may happen that some signers belong to conflicting [segments](https://developer.box.com/reference/resources/shield-information-barrier-segment-member) (user groups). This means that due to the security policies, users are assigned to segments to prevent exchanges or communication that could lead to ethical conflicts. In such a case, an attempt to send the sign request will result in an error.  Read more about [segments and ethical walls](https://support.box.com/hc/en-us/articles/9920431507603-Understanding-Information-Barriers#h_01GFVJEHQA06N7XEZ4GCZ9GFAQ). — item shape: {email?: string, role?: "signer"|"approver"|"final_copy_reader", is_in_person?: bool, order?: int, embed_url_external_user_id?: string, redirect_url?: string, declined_redirect_url?: string, login_required?: bool, verification_phone_number?: string, password?: string, signer_group_id?: string, suppress_notifications?: bool, language?: string}
  --parent-folder: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sign_requests")
  let body = {is_document_preparation_needed: $is_document_preparation_needed, redirect_url: $redirect_url, declined_redirect_url: $declined_redirect_url, are_text_signatures_enabled: $are_text_signatures_enabled, email_subject: $email_subject, email_message: $email_message, are_reminders_enabled: $are_reminders_enabled, name: $name, prefill_tags: $prefill_tags, days_valid: $days_valid, external_id: $external_id, template_id: $template_id, external_system_name: $external_system_name, source_files: $source_files, signature_color: $signature_color, signers: $signers, parent_folder: $parent_folder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workflows
#
# GET /workflows
# operationId: get_workflows
export def "workflows workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts workflow based on request body
#
# POST /workflows/{workflow_id}/start
# operationId: post_workflows_id_start
# --flow shape: {type?: string, id?: string}
# --files item shape: {type?: "file", id?: string}
# --folder shape: {type?: "folder", id?: string}
# --outcomes item shape: {id: string, collaborators?: any, completion_rule?: any, file_collaborator_role?: any, task_collaborators?: any, role?: any}
export def "workflows-start start" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-5 # The type of the parameters object. (e.g. workflow_parameters)
  flow: record # The flow that will be triggered. — shape: {type?: string, id?: string}
  files: list # The array of files for which the workflow should start. All files must be in the workflow's configured folder. — item shape: {type?: "file", id?: string}
  folder: record # The folder object for which the workflow is configured. — shape: {type?: "folder", id?: string}
  --outcomes: list # A configurable outcome the workflow should complete. — item shape: {id: string, collaborators?: any, completion_rule?: any, file_collaborator_role?: any, task_collaborators?: any, role?: any}
]: any -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($workflow_id)/start")
  let body = {type: $type, flow: $flow, files: $files, folder: $folder, outcomes: $outcomes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Box Sign templates
#
# GET /sign_templates
# operationId: get_sign_templates
export def "sign-templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sign_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Box Sign template by ID
#
# GET /sign_templates/{template_id}
# operationId: get_sign_templates_id
export def "sign-templates id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sign_templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Slack integration mappings
#
# GET /integration_mappings/slack
# operationId: get_integration_mappings_slack
export def "integration-mappings-slack slack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --partner-item-type: string@partner-item-type-completer # Mapped item type, for which the mapping should be returned. (e.g. channel)
  --partner-item-id: string # ID of the mapped item, for which the mapping should be returned. (e.g. 12345)
  --box-item-id: string # Box item ID, for which the mappings should be returned. (e.g. 12345)
  --box-item-type: string@box-item-type-completer # Box item type, for which the mappings should be returned. (e.g. folder)
  --is-manually-created: string@bool-completer # Whether the mapping has been manually created. (e.g. true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "partner_item_type" $partner_item_type "scalar") (serialize-qp "partner_item_id" $partner_item_id "scalar") (serialize-qp "box_item_id" $box_item_id "scalar") (serialize-qp "box_item_type" $box_item_type "scalar") (serialize-qp "is_manually_created" $is_manually_created "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integration_mappings/slack" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Slack integration mapping
#
# POST /integration_mappings/slack
# operationId: post_integration_mappings_slack
export def "integration-mappings-slack slack-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  partner_item: any
  box_item: any
  --options: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integration_mappings/slack")
  let body = {partner_item: $partner_item, box_item: $box_item, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Slack integration mapping
#
# PUT /integration_mappings/slack/{integration_mapping_id}
# operationId: put_integration_mappings_slack_id
export def "integration-mappings-slack id-by-integration_mapping_id" [
  integration_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --box-item: any
  --options: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integration_mappings/slack/($integration_mapping_id)")
  let body = {box_item: $box_item, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Slack integration mapping
#
# DELETE /integration_mappings/slack/{integration_mapping_id}
# operationId: delete_integration_mappings_slack_id
export def "integration-mappings-slack id-by-integration_mapping_id-1" [
  integration_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integration_mappings/slack/($integration_mapping_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Teams integration mappings
#
# GET /integration_mappings/teams
# operationId: get_integration_mappings_teams
export def "integration-mappings-teams teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partner-item-type: string@partner-item-type-completer-1 # Mapped item type, for which the mapping should be returned. (e.g. channel)
  --partner-item-id: string # ID of the mapped item, for which the mapping should be returned. (e.g. 12345)
  --box-item-id: string # Box item ID, for which the mappings should be returned. (e.g. 12345)
  --box-item-type: string@box-item-type-completer # Box item type, for which the mappings should be returned. (e.g. folder)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partner_item_type" $partner_item_type "scalar") (serialize-qp "partner_item_id" $partner_item_id "scalar") (serialize-qp "box_item_id" $box_item_id "scalar") (serialize-qp "box_item_type" $box_item_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integration_mappings/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Teams integration mapping
#
# POST /integration_mappings/teams
# operationId: post_integration_mappings_teams
export def "integration-mappings-teams teams-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  partner_item: any
  box_item: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integration_mappings/teams")
  let body = {partner_item: $partner_item, box_item: $box_item} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Teams integration mapping
#
# PUT /integration_mappings/teams/{integration_mapping_id}
# operationId: put_integration_mappings_teams_id
export def "integration-mappings-teams id-by-integration_mapping_id" [
  integration_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --box-item: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integration_mappings/teams/($integration_mapping_id)")
  let body = {box_item: $box_item} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Teams integration mapping
#
# DELETE /integration_mappings/teams/{integration_mapping_id}
# operationId: delete_integration_mappings_teams_id
export def "integration-mappings-teams id-by-integration_mapping_id-1" [
  integration_mapping_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/integration_mappings/teams/($integration_mapping_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ask question
#
# POST /ai/ask
# operationId: post_ai_ask
# --items item shape: {id: string, type: "file"|"hubs", content?: string}
# --dialogue_history item shape: {prompt?: string, answer?: string, created_at?: string}
export def "ai-ask ask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mode: string@mode-completer # Box AI handles text documents with text representations up to 2MB in size, or a maximum of 25 files, whichever comes first. If the text file size exceeds 2MB, the first 2MB of text representation will be processed. Box AI handles image documents with a resolution of 1024 x 1024 pixels, with a maximum of 5 images or 5 pages for multi-page images. If the number of image or image pages exceeds 5, the first 5 images or pages will be processed. If you set mode parameter to `single_item_qa`, the items array can have one element only. Currently Box AI does not support multi-modal requests. If both images and text are sent Box AI will only process the text. (e.g. multiple_item_qa)
  prompt: string # The prompt provided by the client to be answered by the LLM. The prompt's length is limited to 10000 characters. (e.g. What is the value provided by public APIs based on this document?)
  items: list # The items to be processed by the LLM, often files. — item shape: {id: string, type: "file"|"hubs", content?: string}
  --dialogue-history: list # The history of prompts and answers previously passed to the LLM. This provides additional context to the LLM in generating the response. — item shape: {prompt?: string, answer?: string, created_at?: string}
  --include-citations: string@bool-completer # A flag to indicate whether citations should be returned. (e.g. true)
  --ai-agent: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/ask")
  let body = {mode: $mode, prompt: $prompt, items: $items, dialogue_history: $dialogue_history, include_citations: $include_citations, ai_agent: $ai_agent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate text
#
# POST /ai/text_gen
# operationId: post_ai_text_gen
# --items item shape: {id: string, type: "file", content?: string}
# --dialogue_history item shape: {prompt?: string, answer?: string, created_at?: string}
export def "ai-text-gen gen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prompt: string # The prompt provided by the client to be answered by the LLM. The prompt's length is limited to 10000 characters. (e.g. Write an email to a client about the importance of public APIs.)
  items: list # The items to be processed by the LLM, often files. The array can include **exactly one** element.  **Note**: Box AI handles documents with text representations up to 2MB in size. If the file size exceeds 2MB, the first 2MB of text representation will be processed. — item shape: {id: string, type: "file", content?: string}
  --dialogue-history: list # The history of prompts and answers previously passed to the LLM. This parameter provides the additional context to the LLM when generating the response. — item shape: {prompt?: string, answer?: string, created_at?: string}
  --ai-agent: any
]: any -> record<answer: string, created_at: string, completion_reason: string, ai_agent_info: record<models: list<record>, processor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/text_gen")
  let body = {prompt: $prompt, items: $items, dialogue_history: $dialogue_history, ai_agent: $ai_agent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get AI agent default configuration
#
# GET /ai_agent_default
# operationId: get_ai_agent_default
export def "ai-agent-default default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mode: string@mode-completer-1 # The mode to filter the agent config to return. (e.g. ask)
  --language: string # The ISO language code to return the agent config for. If the language is not supported the default agent config is returned. (e.g. ja)
  --model: string # The model to return the default agent config for. (e.g. azure__openai__gpt_4o_mini)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai_agent_default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract metadata (freeform)
#
# POST /ai/extract
# operationId: post_ai_extract
# --items item shape: {id: string, type: "file", content?: string}
export def "ai-extract extract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prompt: string # The prompt provided to a Large Language Model (LLM) in the request. The prompt can be up to 10000 characters long and it can be an XML or a JSON schema. (e.g. \"fields\":[{\"type\":\"string\",\"key\":\"name\",\"displayName\":\"Name\",\"description\":\"The customer name\",\"prompt\":\"Name is always the first word in the document\"},{\"type\":\"date\",\"key\":\"last_contacted_at\",\"displayName\":\"Last Contacted At\",\"description\":\"When this customer was last contacted at\"}])
  items: list # The items that LLM will process. Currently, you can use files only. — item shape: {id: string, type: "file", content?: string}
  --ai-agent: any
]: any -> record<answer: string, created_at: string, completion_reason: string, ai_agent_info: record<models: list<record>, processor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/extract")
  let body = {prompt: $prompt, items: $items, ai_agent: $ai_agent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Extract metadata (structured)
#
# POST /ai/extract_structured
# operationId: post_ai_extract_structured
# --items item shape: {id: string, type: "file", content?: string}
# --metadata_template shape: {template_key?: string, type?: "metadata_template", scope?: string}
# --fields item shape: {key: string, description?: string, displayName?: string, prompt?: string, type?: string, options?: list, fields?: list, taxonomy_key?: string, namespace?: string, options_rules?: any}
export def "ai-extract-structured structured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # The items to be processed by the LLM. Currently you can use files only. — item shape: {id: string, type: "file", content?: string}
  --metadata-template: record # The metadata template containing the fields to extract. For your request to work, you must provide either `metadata_template` or `fields`, but not both. — shape: {template_key?: string, type?: "metadata_template", scope?: string}
  --body-fields: list # The fields to be extracted from the provided items. For your request to work, you must provide either `metadata_template` or `fields`, but not both. — item shape: {key: string, description?: string, displayName?: string, prompt?: string, type?: string, options?: list, fields?: list, taxonomy_key?: string, namespace?: string, options_rules?: any}
  --ai-agent: any
  --include-confidence-score: string@bool-completer # A flag to indicate whether confidence scores for every extracted field should be returned. (e.g. true)
  --include-reference: string@bool-completer # A flag to indicate whether references for every extracted field should be returned. (e.g. true)
  --taxonomy-sources: list # The taxonomy sources to be used for the structured extraction. They can either be an existing file or a taxonomy. For your request to work, `fields` must also be provided. `taxonomy_sources` is not supported with `metadata_template`. (e.g. [{type: taxonomy, taxonomy_key: certification_taxonomy, namespace: enterprise_123}, {type: file, taxonomy_key: industry_taxonomy, id: 1234567890}])
]: any -> record<answer: record, created_at: string, completion_reason: string, confidence_score: record, reference: record, ai_agent_info: record<models: list<record>, processor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/extract_structured")
  let body = {items: $items, metadata_template: $metadata_template, fields: $body_fields, ai_agent: $ai_agent, include_confidence_score: $include_confidence_score, include_reference: $include_reference, taxonomy_sources: $taxonomy_sources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List AI agents
#
# GET /ai_agents
# operationId: get_ai_agents
export def "ai-agents agents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mode: list # The mode to filter the agent config to return. Possible values are: `ask`, `text_gen`, and `extract`. (e.g. [ask, text_gen, extract])
  --qp-fields: list # The fields to return in the response. (e.g. [ask, text_gen, extract])
  --agent-state: list # The state of the agents to return. Possible values are: `enabled`, `disabled` and `enabled_for_selected_users`. (e.g. [enabled])
  --include-box-default: string@bool-completer # Whether to include the Box default agents in the response. (default: false, e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mode" $mode "csv") (serialize-qp "fields" $qp_fields "csv") (serialize-qp "agent_state" $agent_state "csv") (serialize-qp "include_box_default" $include_box_default "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai_agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create AI agent
#
# POST /ai_agents
# operationId: post_ai_agents
# --ask shape: {type: "ai_agent_ask", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, long_text?: record, basic_text?: record, basic_image?: record, spreadsheet?: record, long_text_multi?: record, basic_text_multi?: record, basic_image_multi?: record}
# --text_gen shape: {type: "ai_agent_text_gen", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, basic_gen?: record}
# --extract shape: {type: "ai_agent_extract", access_state: string, description: string, custom_instructions?: string, long_text?: record, basic_text?: record, basic_image?: record}
export def "ai-agents agents-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6 # The type of agent used to handle queries. (e.g. ai_agent)
  name: string # The name of the AI Agent. (e.g. My AI Agent)
  access_state: string # The state of the AI Agent. Possible values are: `enabled`, `disabled`, and `enabled_for_selected_users`. (e.g. enabled)
  --icon-reference: string # The icon reference of the AI Agent. It should have format of the URL `https://cdn01.boxcdn.net/app-assets/aistudio/avatars/<file_name>` where possible values of `file_name` are: `logo_boxAi.png`,`logo_stamp.png`,`logo_legal.png`,`logo_finance.png`,`logo_config.png`,`logo_handshake.png`,`logo_analytics.png`,`logo_classification.png`. (e.g. https://cdn01.boxcdn.net/app-assets/aistudio/avatars/logo_analytics.svg)
  --allowed-entities: list # List of allowed users or groups.
  --ask: record # The AI agent to be used to handle queries. — shape: {type: "ai_agent_ask", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, long_text?: record, basic_text?: record, basic_image?: record, spreadsheet?: record, long_text_multi?: record, basic_text_multi?: record, basic_image_multi?: record}
  --text-gen: record # The AI agent to be used to generate text. — shape: {type: "ai_agent_text_gen", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, basic_gen?: record}
  --extract: record # The AI agent to be used for metadata extraction. — shape: {type: "ai_agent_extract", access_state: string, description: string, custom_instructions?: string, long_text?: record, basic_text?: record, basic_image?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai_agents")
  let body = {type: $type, name: $name, access_state: $access_state, icon_reference: $icon_reference, allowed_entities: $allowed_entities, ask: $ask, text_gen: $text_gen, extract: $extract} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update AI agent
#
# PUT /ai_agents/{agent_id}
# operationId: put_ai_agents_id
# --ask shape: {type: "ai_agent_ask", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, long_text?: record, basic_text?: record, basic_image?: record, spreadsheet?: record, long_text_multi?: record, basic_text_multi?: record, basic_image_multi?: record}
# --text_gen shape: {type: "ai_agent_text_gen", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, basic_gen?: record}
# --extract shape: {type: "ai_agent_extract", access_state: string, description: string, custom_instructions?: string, long_text?: record, basic_text?: record, basic_image?: record}
export def "ai-agents id-by-agent_id" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6 # The type of agent used to handle queries. (e.g. ai_agent)
  name: string # The name of the AI Agent. (e.g. My AI Agent)
  access_state: string # The state of the AI Agent. Possible values are: `enabled`, `disabled`, and `enabled_for_selected_users`. (e.g. enabled)
  --icon-reference: string # The icon reference of the AI Agent. It should have format of the URL `https://cdn01.boxcdn.net/app-assets/aistudio/avatars/<file_name>` where possible values of `file_name` are: `logo_boxAi.png`,`logo_stamp.png`,`logo_legal.png`,`logo_finance.png`,`logo_config.png`,`logo_handshake.png`,`logo_analytics.png`,`logo_classification.png`. (e.g. https://cdn01.boxcdn.net/app-assets/aistudio/avatars/logo_analytics.svg)
  --allowed-entities: list # List of allowed users or groups.
  --ask: record # The AI agent to be used to handle queries. — shape: {type: "ai_agent_ask", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, long_text?: record, basic_text?: record, basic_image?: record, spreadsheet?: record, long_text_multi?: record, basic_text_multi?: record, basic_image_multi?: record}
  --text-gen: record # The AI agent to be used to generate text. — shape: {type: "ai_agent_text_gen", access_state: string, description: string, custom_instructions?: string, suggested_questions?: list, basic_gen?: record}
  --extract: record # The AI agent to be used for metadata extraction. — shape: {type: "ai_agent_extract", access_state: string, description: string, custom_instructions?: string, long_text?: record, basic_text?: record, basic_image?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai_agents/($agent_id)")
  let body = {type: $type, name: $name, access_state: $access_state, icon_reference: $icon_reference, allowed_entities: $allowed_entities, ask: $ask, text_gen: $text_gen, extract: $extract} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get AI agent by agent ID
#
# GET /ai_agents/{agent_id}
# operationId: get_ai_agents_id
export def "ai-agents id-by-agent_id-1" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # The fields to return in the response. (e.g. [ask, text_gen, extract])
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ai_agents/($agent_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete AI agent
#
# DELETE /ai_agents/{agent_id}
# operationId: delete_ai_agents_id
export def "ai-agents id-by-agent_id-2" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai_agents/($agent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create metadata taxonomy
#
# POST /metadata_taxonomies
# operationId: post_metadata_taxonomies
export def "metadata-taxonomies taxonomies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The taxonomy key. If it is not provided in the request body, it will be  generated from the `displayName`. The `displayName` would be converted  to lower case, and all spaces and non-alphanumeric characters replaced  with underscores. (e.g. geography)
  displayName: string # The display name of the taxonomy. (e.g. Geography)
  namespace: string # The namespace of the metadata taxonomy to create. (e.g. enterprise_123456)
]: any -> record<id: string, key: string, displayName: string, namespace: string, levels: table<displayName: string, description: string, level: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata_taxonomies")
  let body = {key: $key, displayName: $displayName, namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metadata taxonomies for namespace
#
# GET /metadata_taxonomies/{namespace}
# operationId: get_metadata_taxonomies_id
export def "metadata-taxonomies id-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metadata taxonomy by taxonomy key
#
# GET /metadata_taxonomies/{namespace}/{taxonomy_key}
# operationId: get_metadata_taxonomies_id_id
export def "metadata-taxonomies id-by-namespace-taxonomy_key" [
  namespace: string
  taxonomy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, key: string, displayName: string, namespace: string, levels: table<displayName: string, description: string, level: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update metadata taxonomy
#
# PATCH /metadata_taxonomies/{namespace}/{taxonomy_key}
# operationId: patch_metadata_taxonomies_id_id
export def "metadata-taxonomies id-by-namespace-taxonomy_key-1" [
  namespace: string
  taxonomy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # The display name of the taxonomy. (e.g. Geography)
]: any -> record<id: string, key: string, displayName: string, namespace: string, levels: table<displayName: string, description: string, level: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)")
  let body = {displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove metadata taxonomy
#
# DELETE /metadata_taxonomies/{namespace}/{taxonomy_key}
# operationId: delete_metadata_taxonomies_id_id
export def "metadata-taxonomies id-by-namespace-taxonomy_key-2" [
  namespace: string
  taxonomy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create metadata taxonomy levels
#
# POST /metadata_taxonomies/{namespace}/{taxonomy_key}/levels
# operationId: post_metadata_taxonomies_id_id_levels
export def "metadata-taxonomies-levels levels" [
  namespace: string
  taxonomy_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/levels")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update metadata taxonomy level
#
# PATCH /metadata_taxonomies/{namespace}/{taxonomy_key}/levels/{level_index}
# operationId: patch_metadata_taxonomies_id_id_levels_id
export def "metadata-taxonomies-levels id" [
  namespace: string
  taxonomy_key: string
  level_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # The display name of the taxonomy level. (e.g. France)
  --description: string # The description of the taxonomy level. (e.g. French Republic)
]: any -> record<displayName: string, description: string, level: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/levels/($level_index)")
  let body = {displayName: $displayName, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add metadata taxonomy level
#
# POST /metadata_taxonomies/{namespace}/{taxonomy_key}/levels:append
# operationId: post_metadata_taxonomies_id_id_levels:append
export def "metadata-taxonomies-levels-append levels:append" [
  namespace: string
  taxonomy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # The display name of the taxonomy level. (e.g. France)
  --description: string # The description of the taxonomy level. (e.g. French Republic)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/levels:append")
  let body = {displayName: $displayName, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete metadata taxonomy level
#
# POST /metadata_taxonomies/{namespace}/{taxonomy_key}/levels:trim
# operationId: post_metadata_taxonomies_id_id_levels:trim
export def "metadata-taxonomies-levels-trim levels:trim" [
  namespace: string
  taxonomy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/levels:trim")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metadata taxonomy nodes
#
# GET /metadata_taxonomies/{namespace}/{taxonomy_key}/nodes
# operationId: get_metadata_taxonomies_id_id_nodes
export def "metadata-taxonomies-nodes nodes-by-namespace-taxonomy_key" [
  namespace: string
  taxonomy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --level: list # Filters results by taxonomy level. Multiple values can be provided.  Results include nodes that match any of the specified values. (e.g. [1])
  --parent: list # Node identifier of a direct parent node. Multiple values can be provided.  Results include nodes that match any of the specified values. (e.g. [c73a9bf3-f377-4210-9159-3df06a481905])
  --ancestor: list # Node identifier of any ancestor node. Multiple values can be provided.  Results include nodes that match any of the specified values. (e.g. [c73a9bf3-f377-4210-9159-3df06a481905, bf8b8213-be1f-4011-bd45-533c0713fa0a])
  --qp-query: string # Query text to search for the taxonomy nodes. (e.g. France)
  --include-total-result-count: string@bool-completer # When set to `true` this provides the total number of nodes that matched the query.  The response will compute counts of up to 10,000 elements. Defaults to `false`. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "multi") (serialize-qp "parent" $parent "multi") (serialize-qp "ancestor" $ancestor "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "include-total-result-count" $include_total_result_count "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create metadata taxonomy node
#
# POST /metadata_taxonomies/{namespace}/{taxonomy_key}/nodes
# operationId: post_metadata_taxonomies_id_id_nodes
export def "metadata-taxonomies-nodes nodes-by-namespace-taxonomy_key-1" [
  namespace: string
  taxonomy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # The display name of the taxonomy node. (e.g. France)
  level: int # The level of the taxonomy node. (e.g. 1)
  --parentId: string # The identifier of the parent taxonomy node.  Omit this field for root-level nodes. (e.g. 99df4513-7102-4896-8228-94635ee9d330)
]: any -> record<id: string, displayName: string, level: int, parentId: string, nodePath: list<string>, ancestors: table<id: string, displayName: string, level: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/nodes")
  let body = {displayName: $displayName, level: $level, parentId: $parentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metadata taxonomy node by ID
#
# GET /metadata_taxonomies/{namespace}/{taxonomy_key}/nodes/{node_id}
# operationId: get_metadata_taxonomies_id_id_nodes_id
export def "metadata-taxonomies-nodes id-by-namespace-taxonomy_key-node_id" [
  namespace: string
  taxonomy_key: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, displayName: string, level: int, parentId: string, nodePath: list<string>, ancestors: table<id: string, displayName: string, level: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/nodes/($node_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update metadata taxonomy node
#
# PATCH /metadata_taxonomies/{namespace}/{taxonomy_key}/nodes/{node_id}
# operationId: patch_metadata_taxonomies_id_id_nodes_id
export def "metadata-taxonomies-nodes id-by-namespace-taxonomy_key-node_id-1" [
  namespace: string
  taxonomy_key: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --displayName: string # The display name of the taxonomy node. (e.g. France)
]: any -> record<id: string, displayName: string, level: int, parentId: string, nodePath: list<string>, ancestors: table<id: string, displayName: string, level: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/nodes/($node_id)")
  let body = {displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove metadata taxonomy node
#
# DELETE /metadata_taxonomies/{namespace}/{taxonomy_key}/nodes/{node_id}
# operationId: delete_metadata_taxonomies_id_id_nodes_id
export def "metadata-taxonomies-nodes id-by-namespace-taxonomy_key-node_id-2" [
  namespace: string
  taxonomy_key: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: int, code: string, message: string, context_info: record, help_url: string, request_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metadata_taxonomies/($namespace)/($taxonomy_key)/nodes/($node_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metadata template's options for taxonomy field
#
# GET /metadata_templates/{namespace}/{template_key}/fields/{field_key}/options
# operationId: get_metadata_templates_id_id_fields_id_options
export def "metadata-templates-fields-options options" [
  namespace: string
  template_key: string
  field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --level: list # Filters results by taxonomy level. Multiple values can be provided.  Results include nodes that match any of the specified values. (e.g. [1])
  --parent: list # Node identifier of a direct parent node. Multiple values can be provided.  Results include nodes that match any of the specified values. (e.g. [c73a9bf3-f377-4210-9159-3df06a481905])
  --ancestor: list # Node identifier of any ancestor node. Multiple values can be provided.  Results include nodes that match any of the specified values. (e.g. [c73a9bf3-f377-4210-9159-3df06a481905, bf8b8213-be1f-4011-bd45-533c0713fa0a])
  --qp-query: string # Query text to search for the taxonomy nodes. (e.g. France)
  --include-total-result-count: string@bool-completer # When set to `true` this provides the total number of nodes that matched the query.  The response will compute counts of up to 10,000 elements. Defaults to `false`. (e.g. true)
  --only-selectable-options: string@bool-completer # When set to `true`, this only returns valid selectable options for this template taxonomy field. Otherwise, it returns all taxonomy nodes, whether or not they are selectable. Defaults to `true`. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination.  This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "multi") (serialize-qp "parent" $parent "multi") (serialize-qp "ancestor" $ancestor "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "include-total-result-count" $include_total_result_count "scalar") (serialize-qp "only-selectable-options" $only_selectable_options "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metadata_templates/($namespace)/($template_key)/fields/($field_key)/options" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
