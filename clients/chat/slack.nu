# Auto-generated client for Slack Web API v1.7.0
# Source: https://raw.githubusercontent.com/slackapi/slack-api-specs/master/web-api/slack_web_openapi_v2.json
# Auth: --token flag or $env.SLACK_WEB_API_TOKEN

const BASE_URL = "https://slack.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SLACK_WEB_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://slack.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "adminappsapprove approve" } } | get name | first)
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

# Approve an app for installation on a workspace.
#
# POST /admin.apps.approve
# Docs: https://api.slack.com/methods/admin.apps.approve — API method documentation
# operationId: admin_apps_approve
export def "adminappsapprove approve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.apps:write`
  --app-id: string # The id of the app to approve.
  --request-id: string # The id of the request to approve.
  --team-id: string
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.apps.approve")
  let body = {app_id: $app_id, request_id: $request_id, team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List approved apps for an org or workspace.
#
# GET /admin.apps.approved.list
# Docs: https://api.slack.com/methods/admin.apps.approved.list — API method documentation
# operationId: admin_apps_approved_list
export def "adminappsapprovedlist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read`
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
  --enterprise-id: string
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "enterprise_id" $enterprise_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.apps.approved.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List app requests for a team/workspace.
#
# GET /admin.apps.requests.list
# Docs: https://api.slack.com/methods/admin.apps.requests.list — API method documentation
# operationId: admin_apps_requests_list
export def "adminappsrequestslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read`
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.apps.requests.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restrict an app for installation on a workspace.
#
# POST /admin.apps.restrict
# Docs: https://api.slack.com/methods/admin.apps.restrict — API method documentation
# operationId: admin_apps_restrict
export def "adminappsrestrict restrict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.apps:write`
  --app-id: string # The id of the app to restrict.
  --request-id: string # The id of the request to restrict.
  --team-id: string
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.apps.restrict")
  let body = {app_id: $app_id, request_id: $request_id, team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List restricted apps for an org or workspace.
#
# GET /admin.apps.restricted.list
# Docs: https://api.slack.com/methods/admin.apps.restricted.list — API method documentation
# operationId: admin_apps_restricted_list
export def "adminappsrestrictedlist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read`
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
  --enterprise-id: string
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "enterprise_id" $enterprise_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.apps.restricted.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a public or private channel.
#
# POST /admin.conversations.archive
# Docs: https://api.slack.com/methods/admin.conversations.archive — API method documentation
# operationId: admin_conversations_archive
export def "adminconversationsarchive archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The channel to archive.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.archive")
  let body = {channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Convert a public channel to a private channel.
#
# POST /admin.conversations.convertToPrivate
# Docs: https://api.slack.com/methods/admin.conversations.convertToPrivate — API method documentation
# operationId: admin_conversations_convertToPrivate
export def "adminconversationsconvert-to-private convertToPrivate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The channel to convert to private.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.convertToPrivate")
  let body = {channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a public or private channel-based conversation.
#
# POST /admin.conversations.create
# Docs: https://api.slack.com/methods/admin.conversations.create — API method documentation
# operationId: admin_conversations_create
export def "adminconversationscreate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  name: string # Name of the public or private channel to create.
  --description: string # Description of the public or private channel to create.
  --is-private: oneof<nothing, bool> # When `true`, creates a private channel instead of a public channel
  --org-wide: oneof<nothing, bool> # When `true`, the channel will be available org-wide. Note: if the channel is not `org_wide=true`, you must specify a `team_id` for this channel
  --team-id: string # The workspace to create the channel in. Note: this argument is required unless you set `org_wide=true`.
]: any -> record<channel_id: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.create")
  let body = {name: $name, description: $description, is_private: $is_private, org_wide: $org_wide, team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a public or private channel.
#
# POST /admin.conversations.delete
# Docs: https://api.slack.com/methods/admin.conversations.delete — API method documentation
# operationId: admin_conversations_delete
export def "adminconversationsdelete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The channel to delete.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.delete")
  let body = {channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Disconnect a connected channel from one or more workspaces.
#
# POST /admin.conversations.disconnectShared
# Docs: https://api.slack.com/methods/admin.conversations.disconnectShared — API method documentation
# operationId: admin_conversations_disconnectShared
export def "adminconversationsdisconnect-shared disconnectShared" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The channel to be disconnected from some workspaces.
  --leaving-team-ids: string # The team to be removed from the channel. Currently only a single team id can be specified.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.disconnectShared")
  let body = {channel_id: $channel_id, leaving_team_ids: $leaving_team_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all disconnected channels—i.e., channels that were once connected to other workspaces and then disconnected—and the corresponding original channel IDs for key revocation with EKM.
#
# GET /admin.conversations.ekm.listOriginalConnectedChannelInfo
# Docs: https://api.slack.com/methods/admin.conversations.ekm.listOriginalConnectedChannelInfo — API method documentation
# operationId: admin_conversations_ekm_listOriginalConnectedChannelInfo
export def "adminconversationsekmlist-original-connected-channel-info listOriginalConnectedChannelInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.conversations:read`
  --channel-ids: string # A comma-separated list of channels to filter to.
  --team-ids: string # A comma-separated list of the workspaces to which the channels you would like returned belong.
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel_ids" $channel_ids "scalar") (serialize-qp "team_ids" $team_ids "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.ekm.listOriginalConnectedChannelInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversation preferences for a public or private channel.
#
# GET /admin.conversations.getConversationPrefs
# Docs: https://api.slack.com/methods/admin.conversations.getConversationPrefs — API method documentation
# operationId: admin_conversations_getConversationPrefs
export def "adminconversationsget-conversation-prefs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel-id: string # The channel to get preferences for.
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read`
]: nothing -> record<ok: bool, prefs: record<can_thread: record<type: list, user: list>, who_can_post: record<type: list, user: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channel_id" $channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.getConversationPrefs" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the workspaces a given public or private channel is connected to within this Enterprise org.
#
# GET /admin.conversations.getTeams
# Docs: https://api.slack.com/methods/admin.conversations.getTeams — API method documentation
# operationId: admin_conversations_getTeams
export def "adminconversationsget-teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel-id: string # The channel to determine connected workspaces within the organization for.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read`
]: nothing -> record<ok: bool, response_metadata: record<next_cursor: string>, team_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.getTeams" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite a user to a public or private channel.
#
# POST /admin.conversations.invite
# Docs: https://api.slack.com/methods/admin.conversations.invite — API method documentation
# operationId: admin_conversations_invite
export def "adminconversationsinvite invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  user_ids: string # The users to invite.
  channel_id: string # The channel that the users will be invited to.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.invite")
  let body = {user_ids: $user_ids, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Rename a public or private channel.
#
# POST /admin.conversations.rename
# Docs: https://api.slack.com/methods/admin.conversations.rename — API method documentation
# operationId: admin_conversations_rename
export def "adminconversationsrename rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The channel to rename.
  name: string
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.rename")
  let body = {channel_id: $channel_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add an allowlist of IDP groups for accessing a channel
#
# POST /admin.conversations.restrictAccess.addGroup
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.addGroup — API method documentation
# operationId: admin_conversations_restrictAccess_addGroup
export def "adminconversationsrestrict-accessadd-group addGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.conversations:write`
  --team-id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
  group_id: string # The [IDP Group](https://slack.com/help/articles/115001435788-Connect-identity-provider-groups-to-your-Enterprise-Grid-org) ID to be an allowlist for the private channel.
  channel_id: string # The channel to link this group to.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.restrictAccess.addGroup")
  let body = {token: $body_token, team_id: $team_id, group_id: $group_id, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all IDP Groups linked to a channel
#
# GET /admin.conversations.restrictAccess.listGroups
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.listGroups — API method documentation
# operationId: admin_conversations_restrictAccess_listGroups
export def "adminconversationsrestrict-accesslist-groups listGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.conversations:read`
  --channel-id: string
  --team-id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.restrictAccess.listGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a linked IDP group linked from a private channel
#
# POST /admin.conversations.restrictAccess.removeGroup
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.removeGroup — API method documentation
# operationId: admin_conversations_restrictAccess_removeGroup
export def "adminconversationsrestrict-accessremove-group removeGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.conversations:write`
  team_id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
  group_id: string # The [IDP Group](https://slack.com/help/articles/115001435788-Connect-identity-provider-groups-to-your-Enterprise-Grid-org) ID to remove from the private channel.
  channel_id: string # The channel to remove the linked group from.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.restrictAccess.removeGroup")
  let body = {token: $body_token, team_id: $team_id, group_id: $group_id, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Search for public or private channels in an Enterprise organization.
#
# GET /admin.conversations.search
# Docs: https://api.slack.com/methods/admin.conversations.search — API method documentation
# operationId: admin_conversations_search
export def "adminconversationssearch search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-ids: string # Comma separated string of team IDs, signifying the workspaces to search through.
  --qp-query: string # Name of the the channel to query by.
  --limit: int # Maximum number of items to be returned. Must be between 1 - 20 both inclusive. Default is 10.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --search-channel-types: string # The type of channel to include or exclude in the search. For example `private` will search private channels, while `private_exclude` will exclude them. For a full list of types, check the [Types section](#types).
  --qp-sort: string # Possible values are `relevant` (search ranking based on what we think is closest), `name` (alphabetical), `member_count` (number of users in the channel), and `created` (date channel was created). You can optionally pair this with the `sort_dir` arg to change how it is sorted 
  --sort-dir: string # Sort direction. Possible values are `asc` for ascending order like (1, 2, 3) or (a, b, c), and `desc` for descending order like (3, 2, 1) or (c, b, a)
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read`
]: nothing -> record<channels: table<accepted_user: string, created: int, creator: string, id: string, is_archived: bool, is_channel: bool, is_frozen: bool, is_general: bool, is_member: bool, is_moved: int, is_mpim: bool, is_non_threadable: bool, is_org_shared: bool, is_pending_ext_shared: bool, is_private: bool, is_read_only: bool, is_shared: bool, is_thread_only: bool, last_read: string, latest: list, members: list, name: string, name_normalized: string, num_members: int, pending_shared: list, previous_names: list, priority: float, purpose: record, topic: record, unlinked: int, unread_count: int, unread_count_display: int>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_ids" $team_ids "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "search_channel_types" $search_channel_types "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.search" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the posting permissions for a public or private channel.
#
# POST /admin.conversations.setConversationPrefs
# Docs: https://api.slack.com/methods/admin.conversations.setConversationPrefs — API method documentation
# operationId: admin_conversations_setConversationPrefs
export def "adminconversationsset-conversation-prefs setConversationPrefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The channel to set the prefs for
  prefs: string # The prefs for this channel in a stringified JSON format.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.setConversationPrefs")
  let body = {channel_id: $channel_id, prefs: $prefs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set the workspaces in an Enterprise grid org that connect to a public or private channel.
#
# POST /admin.conversations.setTeams
# Docs: https://api.slack.com/methods/admin.conversations.setTeams — API method documentation
# operationId: admin_conversations_setTeams
export def "adminconversationsset-teams setTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The encoded `channel_id` to add or remove to workspaces.
  --team-id: string # The workspace to which the channel belongs. Omit this argument if the channel is a cross-workspace shared channel.
  --target-team-ids: string # A comma-separated list of workspaces to which the channel should be shared. Not required if the channel is being shared org-wide.
  --org-channel: oneof<nothing, bool> # True if channel has to be converted to an org channel
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.setTeams")
  let body = {channel_id: $channel_id, team_id: $team_id, target_team_ids: $target_team_ids, org_channel: $org_channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unarchive a public or private channel.
#
# POST /admin.conversations.unarchive
# Docs: https://api.slack.com/methods/admin.conversations.unarchive — API method documentation
# operationId: admin_conversations_unarchive
export def "adminconversationsunarchive unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write`
  channel_id: string # The channel to unarchive.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.unarchive")
  let body = {channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add an emoji.
#
# POST /admin.emoji.add
# Docs: https://api.slack.com/methods/admin.emoji.add — API method documentation
# operationId: admin_emoji_add
export def "adminemojiadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.teams:write`
  name: string # The name of the emoji to be removed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  --body-url: string # The URL of a file to use as an image for the emoji. Square images under 128KB and with transparent backgrounds work best.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.add")
  let body = {token: $body_token, name: $name, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add an emoji alias.
#
# POST /admin.emoji.addAlias
# Docs: https://api.slack.com/methods/admin.emoji.addAlias — API method documentation
# operationId: admin_emoji_addAlias
export def "adminemojiadd-alias addAlias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.teams:write`
  name: string # The name of the emoji to be aliased. Colons (`:myemoji:`) around the value are not required, although they may be included.
  alias_for: string # The alias of the emoji.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.addAlias")
  let body = {token: $body_token, name: $name, alias_for: $alias_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List emoji for an Enterprise Grid organization.
#
# GET /admin.emoji.list
# Docs: https://api.slack.com/methods/admin.emoji.list — API method documentation
# operationId: admin_emoji_list
export def "adminemojilist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read`
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.emoji.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an emoji across an Enterprise Grid organization
#
# POST /admin.emoji.remove
# Docs: https://api.slack.com/methods/admin.emoji.remove — API method documentation
# operationId: admin_emoji_remove
export def "adminemojiremove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.teams:write`
  name: string # The name of the emoji to be removed. Colons (`:myemoji:`) around the value are not required, although they may be included.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.remove")
  let body = {token: $body_token, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Rename an emoji.
#
# POST /admin.emoji.rename
# Docs: https://api.slack.com/methods/admin.emoji.rename — API method documentation
# operationId: admin_emoji_rename
export def "adminemojirename rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.teams:write`
  name: string # The name of the emoji to be renamed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  new_name: string # The new name of the emoji.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.rename")
  let body = {token: $body_token, name: $name, new_name: $new_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Approve a workspace invite request.
#
# POST /admin.inviteRequests.approve
# Docs: https://api.slack.com/methods/admin.inviteRequests.approve — API method documentation
# operationId: admin_inviteRequests_approve
export def "admininvite-requestsapprove approve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:write`
  --team-id: string # ID for the workspace where the invite request was made.
  invite_request_id: string # ID of the request to invite.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.inviteRequests.approve")
  let body = {team_id: $team_id, invite_request_id: $invite_request_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all approved workspace invite requests.
#
# GET /admin.inviteRequests.approved.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.approved.list — API method documentation
# operationId: admin_inviteRequests_approved_list
export def "admininvite-requestsapprovedlist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous API response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000, both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.inviteRequests.approved.list" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all denied workspace invite requests.
#
# GET /admin.inviteRequests.denied.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.denied.list — API method documentation
# operationId: admin_inviteRequests_denied_list
export def "admininvite-requestsdeniedlist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous api response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000 both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.inviteRequests.denied.list" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deny a workspace invite request.
#
# POST /admin.inviteRequests.deny
# Docs: https://api.slack.com/methods/admin.inviteRequests.deny — API method documentation
# operationId: admin_inviteRequests_deny
export def "admininvite-requestsdeny deny" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:write`
  --team-id: string # ID for the workspace where the invite request was made.
  invite_request_id: string # ID of the request to invite.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.inviteRequests.deny")
  let body = {team_id: $team_id, invite_request_id: $invite_request_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all pending workspace invite requests.
#
# GET /admin.inviteRequests.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.list — API method documentation
# operationId: admin_inviteRequests_list
export def "admininvite-requestslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous API response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000, both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.inviteRequests.list" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all of the admins on a given workspace.
#
# GET /admin.teams.admins.list
# Docs: https://api.slack.com/methods/admin.teams.admins.list — API method documentation
# operationId: admin_teams_admins_list
export def "adminteamsadminslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read`
  --limit: int # The maximum number of items to return.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --team-id: string
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.admins.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Enterprise team.
#
# POST /admin.teams.create
# Docs: https://api.slack.com/methods/admin.teams.create — API method documentation
# operationId: admin_teams_create
export def "adminteamscreate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write`
  team_domain: string # Team domain (for example, slacksoftballteam).
  team_name: string # Team name (for example, Slack Softball Team).
  --team-description: string # Description for the team.
  --team-discoverability: string # Who can join the team. A team's discoverability can be `open`, `closed`, `invite_only`, or `unlisted`.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.create")
  let body = {team_domain: $team_domain, team_name: $team_name, team_description: $team_description, team_discoverability: $team_discoverability} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all teams on an Enterprise organization
#
# GET /admin.teams.list
# Docs: https://api.slack.com/methods/admin.teams.list — API method documentation
# operationId: admin_teams_list
export def "adminteamslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of items to return. Must be between 1 - 100 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.list" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all of the owners on a given workspace.
#
# GET /admin.teams.owners.list
# Docs: https://api.slack.com/methods/admin.teams.owners.list — API method documentation
# operationId: admin_teams_owners_list
export def "adminteamsownerslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read`
  --team-id: string
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.owners.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch information about settings in a workspace
#
# GET /admin.teams.settings.info
# Docs: https://api.slack.com/methods/admin.teams.settings.info — API method documentation
# operationId: admin_teams_settings_info
export def "adminteamssettingsinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.settings.info" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the default channels of a workspace.
#
# POST /admin.teams.settings.setDefaultChannels
# Docs: https://api.slack.com/methods/admin.teams.settings.setDefaultChannels — API method documentation
# operationId: admin_teams_settings_setDefaultChannels
export def "adminteamssettingsset-default-channels setDefaultChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.teams:write`
  team_id: string # ID for the workspace to set the default channel for.
  channel_ids: string # An array of channel IDs.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.settings.setDefaultChannels")
  let body = {token: $body_token, team_id: $team_id, channel_ids: $channel_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set the description of a given workspace.
#
# POST /admin.teams.settings.setDescription
# Docs: https://api.slack.com/methods/admin.teams.settings.setDescription — API method documentation
# operationId: admin_teams_settings_setDescription
export def "adminteamssettingsset-description setDescription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write`
  team_id: string # ID for the workspace to set the description for.
  description: string # The new description for the workspace.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.settings.setDescription")
  let body = {team_id: $team_id, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# An API method that allows admins to set the discoverability of a given workspace
#
# POST /admin.teams.settings.setDiscoverability
# Docs: https://api.slack.com/methods/admin.teams.settings.setDiscoverability — API method documentation
# operationId: admin_teams_settings_setDiscoverability
export def "adminteamssettingsset-discoverability setDiscoverability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write`
  team_id: string # The ID of the workspace to set discoverability on.
  discoverability: string # This workspace's discovery setting. It must be set to one of `open`, `invite_only`, `closed`, or `unlisted`.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.settings.setDiscoverability")
  let body = {team_id: $team_id, discoverability: $discoverability} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Sets the icon of a workspace.
#
# POST /admin.teams.settings.setIcon
# Docs: https://api.slack.com/methods/admin.teams.settings.setIcon — API method documentation
# operationId: admin_teams_settings_setIcon
export def "adminteamssettingsset-icon setIcon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `admin.teams:write`
  image_url: string # Image URL for the icon
  team_id: string # ID for the workspace to set the icon for.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.settings.setIcon")
  let body = {token: $body_token, image_url: $image_url, team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set the name of a given workspace.
#
# POST /admin.teams.settings.setName
# Docs: https://api.slack.com/methods/admin.teams.settings.setName — API method documentation
# operationId: admin_teams_settings_setName
export def "adminteamssettingsset-name setName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write`
  team_id: string # ID for the workspace to set the name for.
  name: string # The new name of the workspace.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.settings.setName")
  let body = {team_id: $team_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add one or more default channels to an IDP group.
#
# POST /admin.usergroups.addChannels
# Docs: https://api.slack.com/methods/admin.usergroups.addChannels — API method documentation
# operationId: admin_usergroups_addChannels
export def "adminusergroupsadd-channels addChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:write`
  usergroup_id: string # ID of the IDP group to add default channels for.
  --team-id: string # The workspace to add default channels in.
  channel_ids: string # Comma separated string of channel IDs.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.usergroups.addChannels")
  let body = {usergroup_id: $usergroup_id, team_id: $team_id, channel_ids: $channel_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Associate one or more default workspaces with an organization-wide IDP group.
#
# POST /admin.usergroups.addTeams
# Docs: https://api.slack.com/methods/admin.usergroups.addTeams — API method documentation
# operationId: admin_usergroups_addTeams
export def "adminusergroupsadd-teams addTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write`
  usergroup_id: string # An encoded usergroup (IDP Group) ID.
  team_ids: string # A comma separated list of encoded team (workspace) IDs. Each workspace *MUST* belong to the organization associated with the token.
  --auto-provision: oneof<nothing, bool> # When `true`, this method automatically creates new workspace accounts for the IDP group members.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.usergroups.addTeams")
  let body = {usergroup_id: $usergroup_id, team_ids: $team_ids, auto_provision: $auto_provision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List the channels linked to an org-level IDP group (user group).
#
# GET /admin.usergroups.listChannels
# Docs: https://api.slack.com/methods/admin.usergroups.listChannels — API method documentation
# operationId: admin_usergroups_listChannels
export def "adminusergroupslist-channels listChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --usergroup-id: string # ID of the IDP group to list default channels for.
  --team-id: string # ID of the the workspace.
  --include-num-members: oneof<nothing, bool> # Flag to include or exclude the count of members per channel.
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "usergroup_id" $usergroup_id "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "include_num_members" $include_num_members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.usergroups.listChannels" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove one or more default channels from an org-level IDP group (user group).
#
# POST /admin.usergroups.removeChannels
# Docs: https://api.slack.com/methods/admin.usergroups.removeChannels — API method documentation
# operationId: admin_usergroups_removeChannels
export def "adminusergroupsremove-channels removeChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:write`
  usergroup_id: string # ID of the IDP Group
  channel_ids: string # Comma-separated string of channel IDs
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.usergroups.removeChannels")
  let body = {usergroup_id: $usergroup_id, channel_ids: $channel_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add an Enterprise user to a workspace.
#
# POST /admin.users.assign
# Docs: https://api.slack.com/methods/admin.users.assign — API method documentation
# operationId: admin_users_assign
export def "adminusersassign assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to add to the workspace.
  --is-restricted: oneof<nothing, bool> # True if user should be added to the workspace as a guest.
  --is-ultra-restricted: oneof<nothing, bool> # True if user should be added to the workspace as a single-channel guest.
  --channel-ids: string # Comma separated values of channel IDs to add user in the new workspace.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.assign")
  let body = {team_id: $team_id, user_id: $user_id, is_restricted: $is_restricted, is_ultra_restricted: $is_ultra_restricted, channel_ids: $channel_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Invite a user to a workspace.
#
# POST /admin.users.invite
# Docs: https://api.slack.com/methods/admin.users.invite — API method documentation
# operationId: admin_users_invite
export def "adminusersinvite invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # The ID (`T1234`) of the workspace.
  email: string # The email address of the person to invite.
  channel_ids: string # A comma-separated list of `channel_id`s for this user to join. At least one channel is required.
  --custom-message: string # An optional message to send to the user in the invite email.
  --real-name: string # Full name of the user.
  --resend: oneof<nothing, bool> # Allow this invite to be resent in the future if a user has not signed up yet. (default: false)
  --is-restricted: oneof<nothing, bool> # Is this user a multi-channel guest user? (default: false)
  --is-ultra-restricted: oneof<nothing, bool> # Is this user a single channel guest user? (default: false)
  --guest-expiration-ts: string # Timestamp when guest account should be disabled. Only include this timestamp if you are inviting a guest user and you want their account to expire on a certain date.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.invite")
  let body = {team_id: $team_id, email: $email, channel_ids: $channel_ids, custom_message: $custom_message, real_name: $real_name, resend: $resend, is_restricted: $is_restricted, is_ultra_restricted: $is_ultra_restricted, guest_expiration_ts: $guest_expiration_ts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List users on a workspace
#
# GET /admin.users.list
# Docs: https://api.slack.com/methods/admin.users.list — API method documentation
# operationId: admin_users_list
export def "adminuserslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string # The ID (`T1234`) of the workspace.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --limit: int # Limit for how many users to be retrieved per page
  --hdr-token: string # Authentication token. Requires scope: `admin.users:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.users.list" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a user from a workspace.
#
# POST /admin.users.remove
# Docs: https://api.slack.com/methods/admin.users.remove — API method documentation
# operationId: admin_users_remove
export def "adminusersremove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to remove.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.remove")
  let body = {team_id: $team_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Invalidate a single session for a user by session_id
#
# POST /admin.users.session.invalidate
# Docs: https://api.slack.com/methods/admin.users.session.invalidate — API method documentation
# operationId: admin_users_session_invalidate
export def "adminuserssessioninvalidate invalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # ID of the team that the session belongs to
  session_id: int
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.session.invalidate")
  let body = {team_id: $team_id, session_id: $session_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Wipes all valid sessions on all devices for a given user
#
# POST /admin.users.session.reset
# Docs: https://api.slack.com/methods/admin.users.session.reset — API method documentation
# operationId: admin_users_session_reset
export def "adminuserssessionreset reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  user_id: string # The ID of the user to wipe sessions for
  --mobile-only: oneof<nothing, bool> # Only expire mobile sessions (default: false)
  --web-only: oneof<nothing, bool> # Only expire web sessions (default: false)
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.session.reset")
  let body = {user_id: $user_id, mobile_only: $mobile_only, web_only: $web_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set an existing guest, regular user, or owner to be an admin user.
#
# POST /admin.users.setAdmin
# Docs: https://api.slack.com/methods/admin.users.setAdmin — API method documentation
# operationId: admin_users_setAdmin
export def "adminusersset-admin setAdmin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to designate as an admin.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.setAdmin")
  let body = {team_id: $team_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set an expiration for a guest user
#
# POST /admin.users.setExpiration
# Docs: https://api.slack.com/methods/admin.users.setExpiration — API method documentation
# operationId: admin_users_setExpiration
export def "adminusersset-expiration setExpiration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to set an expiration for.
  expiration_ts: int # Timestamp when guest account should be disabled.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.setExpiration")
  let body = {team_id: $team_id, user_id: $user_id, expiration_ts: $expiration_ts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set an existing guest, regular user, or admin user to be a workspace owner.
#
# POST /admin.users.setOwner
# Docs: https://api.slack.com/methods/admin.users.setOwner — API method documentation
# operationId: admin_users_setOwner
export def "adminusersset-owner setOwner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # Id of the user to promote to owner.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.setOwner")
  let body = {team_id: $team_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set an existing guest user, admin user, or owner to be a regular user.
#
# POST /admin.users.setRegular
# Docs: https://api.slack.com/methods/admin.users.setRegular — API method documentation
# operationId: admin_users_setRegular
export def "adminusersset-regular setRegular" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write`
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to designate as a regular user.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.users.setRegular")
  let body = {team_id: $team_id, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Checks API calling code.
#
# GET /api.test
# Docs: https://api.slack.com/methods/api.test — API method documentation
# operationId: api_test
export def "apitest test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-error: string # Error response to return
  --foo: string # example property to return
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "error" $qp_error "scalar") (serialize-qp "foo" $foo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api.test" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of authorizations for the given event context. Each authorization represents an app installation that the event is visible to.
#
# GET /apps.event.authorizations.list
# Docs: https://api.slack.com/methods/apps.event.authorizations.list — API method documentation
# operationId: apps_event_authorizations_list
export def "appseventauthorizationslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-context: string
  --cursor: string
  --limit: int
  --hdr-token: string # Authentication token. Requires scope: `authorizations:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event_context" $event_context "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.event.authorizations.list" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns list of permissions this app has on a team.
#
# GET /apps.permissions.info
# Docs: https://api.slack.com/methods/apps.permissions.info — API method documentation
# operationId: apps_permissions_info
export def "appspermissionsinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<info: record<app_home: record<resources: record, scopes: list>, channel: record<resources: record, scopes: list>, group: record<resources: record, scopes: list>, im: record<resources: record, scopes: list>, mpim: record<resources: record, scopes: list>, team: record<resources: record, scopes: list>>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Allows an app to request additional scopes
#
# GET /apps.permissions.request
# Docs: https://api.slack.com/methods/apps.permissions.request — API method documentation
# operationId: apps_permissions_request
export def "appspermissionsrequest request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
  --scopes: string # A comma separated list of scopes to request for
  --trigger-id: string # Token used to trigger the permissions API
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "scopes" $scopes "scalar") (serialize-qp "trigger_id" $trigger_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.request" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns list of resource grants this app has on a team.
#
# GET /apps.permissions.resources.list
# Docs: https://api.slack.com/methods/apps.permissions.resources.list — API method documentation
# operationId: apps_permissions_resources_list
export def "appspermissionsresourceslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --limit: int # The maximum number of items to return.
]: nothing -> record<ok: bool, resources: table<id: string, type: string>, response_metadata: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.resources.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns list of scopes this app has on a team.
#
# GET /apps.permissions.scopes.list
# Docs: https://api.slack.com/methods/apps.permissions.scopes.list — API method documentation
# operationId: apps_permissions_scopes_list
export def "appspermissionsscopeslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<ok: bool, scopes: record<app_home: list<string>, channel: list<string>, group: list<string>, im: list<string>, mpim: list<string>, team: list<string>, user: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.scopes.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns list of user grants and corresponding scopes this app has on a team.
#
# GET /apps.permissions.users.list
# Docs: https://api.slack.com/methods/apps.permissions.users.list — API method documentation
# operationId: apps_permissions_users_list
export def "appspermissionsuserslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --limit: int # The maximum number of items to return.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.users.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables an app to trigger a permissions modal to grant an app access to a user access scope.
#
# GET /apps.permissions.users.request
# Docs: https://api.slack.com/methods/apps.permissions.users.request — API method documentation
# operationId: apps_permissions_users_request
export def "appspermissionsusersrequest request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
  --scopes: string # A comma separated list of user scopes to request for
  --trigger-id: string # Token used to trigger the request
  --user: string # The user this scope is being requested for
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "scopes" $scopes "scalar") (serialize-qp "trigger_id" $trigger_id "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.users.request" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Uninstalls your app from a workspace.
#
# GET /apps.uninstall
# Docs: https://api.slack.com/methods/apps.uninstall — API method documentation
# operationId: apps_uninstall
export def "appsuninstall uninstall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.uninstall" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revokes a token.
#
# GET /auth.revoke
# Docs: https://api.slack.com/methods/auth.revoke — API method documentation
# operationId: auth_revoke
export def "authrevoke revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
  --test: oneof<nothing, bool> # Setting this parameter to `1` triggers a _testing mode_ where the specified token will not actually be revoked.
]: nothing -> record<ok: bool, revoked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "test" $test "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auth.revoke" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checks authentication & identity.
#
# GET /auth.test
# Docs: https://api.slack.com/methods/auth.test — API method documentation
# operationId: auth_test
export def "authtest test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<bot_id: string, is_enterprise_install: bool, ok: bool, team: string, team_id: string, url: string, user: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth.test")
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a bot user.
#
# GET /bots.info
# Docs: https://api.slack.com/methods/bots.info — API method documentation
# operationId: bots_info
export def "botsinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `users:read`
  --bot: string # Bot user to get info on
]: nothing -> record<bot: record<app_id: string, deleted: bool, icons: record<image_36: string, image_48: string, image_72: string>, id: string, name: string, updated: int, user_id: string>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "bot" $bot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bots.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Registers a new Call.
#
# POST /calls.add
# Docs: https://api.slack.com/methods/calls.add — API method documentation
# operationId: calls_add
export def "callsadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `calls:write`
  external_unique_id: string # An ID supplied by the 3rd-party Call provider. It must be unique across all Calls from that service.
  --external-display-id: string # An optional, human-readable ID supplied by the 3rd-party Call provider. If supplied, this ID will be displayed in the Call object.
  join_url: string # The URL required for a client to join the Call.
  --desktop-app-join-url: string # When supplied, available Slack clients will attempt to directly launch the 3rd-party Call with this URL.
  --date-start: int # Call start time in UTC UNIX timestamp format
  --title: string # The name of the Call.
  --created-by: string # The valid Slack user ID of the user who created this Call. When this method is called with a user token, the `created_by` field is optional and defaults to the authed user of the token. Otherwise, the field is required.
  --users: string # The list of users to register as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls.add")
  let body = {external_unique_id: $external_unique_id, external_display_id: $external_display_id, join_url: $join_url, desktop_app_join_url: $desktop_app_join_url, date_start: $date_start, title: $title, created_by: $created_by, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Ends a Call.
#
# POST /calls.end
# Docs: https://api.slack.com/methods/calls.end — API method documentation
# operationId: calls_end
export def "callsend end" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `calls:write`
  id: string # `id` returned when registering the call using the [`calls.add`](/methods/calls.add) method.
  --duration: int # Call duration in seconds
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls.end")
  let body = {id: $id, duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns information about a Call.
#
# GET /calls.info
# Docs: https://api.slack.com/methods/calls.info — API method documentation
# operationId: calls_info
export def "callsinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # `id` of the Call returned by the [`calls.add`](/methods/calls.add) method.
  --hdr-token: string # Authentication token. Requires scope: `calls:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calls.info" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Registers new participants added to a Call.
#
# POST /calls.participants.add
# Docs: https://api.slack.com/methods/calls.participants.add — API method documentation
# operationId: calls_participants_add
export def "callsparticipantsadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `calls:write`
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  users: string # The list of users to add as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls.participants.add")
  let body = {id: $id, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Registers participants removed from a Call.
#
# POST /calls.participants.remove
# Docs: https://api.slack.com/methods/calls.participants.remove — API method documentation
# operationId: calls_participants_remove
export def "callsparticipantsremove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `calls:write`
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  users: string # The list of users to remove as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls.participants.remove")
  let body = {id: $id, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates information about a Call.
#
# POST /calls.update
# Docs: https://api.slack.com/methods/calls.update — API method documentation
# operationId: calls_update
export def "callsupdate update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `calls:write`
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  --title: string # The name of the Call.
  --join-url: string # The URL required for a client to join the Call.
  --desktop-app-join-url: string # When supplied, available Slack clients will attempt to directly launch the 3rd-party Call with this URL.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls.update")
  let body = {id: $id, title: $title, join_url: $join_url, desktop_app_join_url: $desktop_app_join_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deletes a message.
#
# POST /chat.delete
# Docs: https://api.slack.com/methods/chat.delete — API method documentation
# operationId: chat_delete
export def "chatdelete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `chat:write`
  --ts: float # Timestamp of the message to be deleted.
  --channel: string # Channel containing the message to be deleted.
  --as-user: oneof<nothing, bool> # Pass true to delete the message as the authed user with `chat:write:user` scope. [Bot users](/bot-users) in this context are considered authed users. If unused or false, the message will be deleted with `chat:write:bot` scope.
]: any -> record<channel: string, ok: bool, ts: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.delete")
  let body = {ts: $ts, channel: $channel, as_user: $as_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deletes a pending scheduled message from the queue.
#
# POST /chat.deleteScheduledMessage
# Docs: https://api.slack.com/methods/chat.deleteScheduledMessage — API method documentation
# operationId: chat_deleteScheduledMessage
export def "chatdelete-scheduled-message post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `chat:write`
  --as-user: oneof<nothing, bool> # Pass true to delete the message as the authed user with `chat:write:user` scope. [Bot users](/bot-users) in this context are considered authed users. If unused or false, the message will be deleted with `chat:write:bot` scope.
  channel: string # The channel the scheduled_message is posting to
  scheduled_message_id: string # `scheduled_message_id` returned from call to chat.scheduleMessage
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.deleteScheduledMessage")
  let body = {as_user: $as_user, channel: $channel, scheduled_message_id: $scheduled_message_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a permalink URL for a specific extant message
#
# GET /chat.getPermalink
# Docs: https://api.slack.com/methods/chat.getPermalink — API method documentation
# operationId: chat_getPermalink
export def "chatget-permalink get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `none`
  --channel: string # The ID of the conversation or channel containing the message
  --message-ts: string # A message's `ts` value, uniquely identifying it within a channel
]: nothing -> record<channel: string, ok: bool, permalink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "message_ts" $message_ts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat.getPermalink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Share a me message into a channel.
#
# POST /chat.meMessage
# Docs: https://api.slack.com/methods/chat.meMessage — API method documentation
# operationId: chat_meMessage
export def "chatme-message meMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `chat:write`
  --channel: string # Channel to send message to. Can be a public channel, private group or IM channel. Can be an encoded ID, or a name.
  --text: string # Text of the message to send.
]: any -> record<channel: string, ok: bool, ts: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.meMessage")
  let body = {channel: $channel, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Sends an ephemeral message to a user in a channel.
#
# POST /chat.postEphemeral
# Docs: https://api.slack.com/methods/chat.postEphemeral — API method documentation
# operationId: chat_postEphemeral
export def "chatpost-ephemeral post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `chat:write`
  --as-user: oneof<nothing, bool> # Pass true to post the message as the authed user. Defaults to true if the chat:write:bot scope is not included. Otherwise, defaults to false.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string.
  --blocks: string # A JSON-based array of structured blocks, presented as a URL-encoded string.
  channel: string # Channel, private group, or IM channel to send message to. Can be an encoded ID, or a name.
  --icon-emoji: string # Emoji to use as the icon for this message. Overrides `icon_url`. Must be used in conjunction with `as_user` set to `false`, otherwise ignored. See [authorship](#authorship) below.
  --icon-url: string # URL to an image to use as the icon for this message. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
  --link-names: oneof<nothing, bool> # Find and link channel names and usernames.
  --parse: string # Change how messages are treated. Defaults to `none`. See [below](#formatting).
  --text: string # How this field works and whether it is required depends on other fields you use in your API call. [See below](#text_usage) for more detail.
  --thread-ts: string # Provide another message's `ts` value to post this message in a thread. Avoid using a reply's `ts` value; use its parent's value instead. Ephemeral messages in threads are only shown if there is already an active thread.
  user: string # `id` of the user who will receive the ephemeral message. The user should be in the channel specified by the `channel` argument.
  --username: string # Set your bot's user name. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
]: any -> record<message_ts: string, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.postEphemeral")
  let body = {as_user: $as_user, attachments: $attachments, blocks: $blocks, channel: $channel, icon_emoji: $icon_emoji, icon_url: $icon_url, link_names: $link_names, parse: $parse, text: $text, thread_ts: $thread_ts, user: $user, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Sends a message to a channel.
#
# POST /chat.postMessage
# Docs: https://api.slack.com/methods/chat.postMessage — API method documentation
# operationId: chat_postMessage
export def "chatpost-message post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `chat:write`
  --as-user: string # Pass true to post the message as the authed user, instead of as a bot. Defaults to false. See [authorship](#authorship) below.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string.
  --blocks: string # A JSON-based array of structured blocks, presented as a URL-encoded string.
  channel: string # Channel, private group, or IM channel to send message to. Can be an encoded ID, or a name. See [below](#channels) for more details.
  --icon-emoji: string # Emoji to use as the icon for this message. Overrides `icon_url`. Must be used in conjunction with `as_user` set to `false`, otherwise ignored. See [authorship](#authorship) below.
  --icon-url: string # URL to an image to use as the icon for this message. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
  --link-names: oneof<nothing, bool> # Find and link channel names and usernames.
  --mrkdwn: oneof<nothing, bool> # Disable Slack markup parsing by setting to `false`. Enabled by default.
  --parse: string # Change how messages are treated. Defaults to `none`. See [below](#formatting).
  --reply-broadcast: oneof<nothing, bool> # Used in conjunction with `thread_ts` and indicates whether reply should be made visible to everyone in the channel or conversation. Defaults to `false`.
  --text: string # How this field works and whether it is required depends on other fields you use in your API call. [See below](#text_usage) for more detail.
  --thread-ts: string # Provide another message's `ts` value to make this message a reply. Avoid using a reply's `ts` value; use its parent instead.
  --unfurl-links: oneof<nothing, bool> # Pass true to enable unfurling of primarily text-based content.
  --unfurl-media: oneof<nothing, bool> # Pass false to disable unfurling of media content.
  --username: string # Set your bot's user name. Must be used in conjunction with `as_user` set to false, otherwise ignored. See [authorship](#authorship) below.
]: any -> record<channel: string, message: record<attachments: list<record>, blocks: list<record>, bot_id: list<any>, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, client_msg_id: string, comment: record<comment: string, created: int, id: string, is_intro: bool, is_starred: bool, num_stars: int, pinned_info: record, pinned_to: list, reactions: list, timestamp: int, user: string>, display_as_bot: bool, file: record<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, files: list<record>, icons: record<emoji: string, image_64: string>, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list<string>, purpose: string, reactions: list<record>, reply_count: int, reply_users: list<string>, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record<avatar_hash: string, display_name: string, display_name_normalized: string, first_name: string, image_72: string, is_restricted: bool, is_ultra_restricted: bool, name: string, real_name: string, real_name_normalized: string, team: string>, user_team: string, username: string>, ok: bool, ts: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.postMessage")
  let body = {as_user: $as_user, attachments: $attachments, blocks: $blocks, channel: $channel, icon_emoji: $icon_emoji, icon_url: $icon_url, link_names: $link_names, mrkdwn: $mrkdwn, parse: $parse, reply_broadcast: $reply_broadcast, text: $text, thread_ts: $thread_ts, unfurl_links: $unfurl_links, unfurl_media: $unfurl_media, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Schedules a message to be sent to a channel.
#
# POST /chat.scheduleMessage
# Docs: https://api.slack.com/methods/chat.scheduleMessage — API method documentation
# operationId: chat_scheduleMessage
export def "chatschedule-message scheduleMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `chat:write`
  --channel: string # Channel, private group, or DM channel to send message to. Can be an encoded ID, or a name. See [below](#channels) for more details.
  --text: string # How this field works and whether it is required depends on other fields you use in your API call. [See below](#text_usage) for more detail.
  --post-at: string # Unix EPOCH timestamp of time in future to send the message.
  --parse: string # Change how messages are treated. Defaults to `none`. See [chat.postMessage](chat.postMessage#formatting).
  --as-user: oneof<nothing, bool> # Pass true to post the message as the authed user, instead of as a bot. Defaults to false. See [chat.postMessage](chat.postMessage#authorship).
  --link-names: oneof<nothing, bool> # Find and link channel names and usernames.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string.
  --blocks: string # A JSON-based array of structured blocks, presented as a URL-encoded string.
  --unfurl-links: oneof<nothing, bool> # Pass true to enable unfurling of primarily text-based content.
  --unfurl-media: oneof<nothing, bool> # Pass false to disable unfurling of media content.
  --thread-ts: float # Provide another message's `ts` value to make this message a reply. Avoid using a reply's `ts` value; use its parent instead.
  --reply-broadcast: oneof<nothing, bool> # Used in conjunction with `thread_ts` and indicates whether reply should be made visible to everyone in the channel or conversation. Defaults to `false`.
]: any -> record<channel: string, message: record<bot_id: string, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, team: string, text: string, type: string, user: string, username: string>, ok: bool, post_at: int, scheduled_message_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.scheduleMessage")
  let body = {channel: $channel, text: $text, post_at: $post_at, parse: $parse, as_user: $as_user, link_names: $link_names, attachments: $attachments, blocks: $blocks, unfurl_links: $unfurl_links, unfurl_media: $unfurl_media, thread_ts: $thread_ts, reply_broadcast: $reply_broadcast} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns a list of scheduled messages.
#
# GET /chat.scheduledMessages.list
# Docs: https://api.slack.com/methods/chat.scheduledMessages.list — API method documentation
# operationId: chat_scheduledMessages_list
export def "chatscheduled-messageslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel: string # The channel of the scheduled messages
  --latest: float # A UNIX timestamp of the latest value in the time range
  --oldest: float # A UNIX timestamp of the oldest value in the time range
  --limit: int # Maximum number of original entries to return.
  --cursor: string # For pagination purposes, this is the `cursor` value returned from a previous call to `chat.scheduledmessages.list` indicating where you want to start this call from.
  --hdr-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<ok: bool, response_metadata: record<next_cursor: string>, scheduled_messages: table<channel_id: string, date_created: int, id: string, post_at: int, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channel" $channel "scalar") (serialize-qp "latest" $latest "scalar") (serialize-qp "oldest" $oldest "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat.scheduledMessages.list" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provide custom unfurl behavior for user-posted URLs
#
# POST /chat.unfurl
# Docs: https://api.slack.com/methods/chat.unfurl — API method documentation
# operationId: chat_unfurl
export def "chatunfurl unfurl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `links:write`
  channel: string # Channel ID of the message
  ts: string # Timestamp of the message to add unfurl behavior to.
  --unfurls: string # URL-encoded JSON map with keys set to URLs featured in the the message, pointing to their unfurl blocks or message attachments.
  --user-auth-message: string # Provide a simply-formatted string to send as an ephemeral message to the user as invitation to authenticate further and enable full unfurling behavior
  --user-auth-required: oneof<nothing, bool> # Set to `true` or `1` to indicate the user must install your Slack app to trigger unfurls for this domain
  --user-auth-url: string # Send users to this custom URL where they will complete authentication in your app to fully trigger unfurling. Value should be properly URL-encoded.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.unfurl")
  let body = {channel: $channel, ts: $ts, unfurls: $unfurls, user_auth_message: $user_auth_message, user_auth_required: $user_auth_required, user_auth_url: $user_auth_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates a message.
#
# POST /chat.update
# Docs: https://api.slack.com/methods/chat.update — API method documentation
# operationId: chat_update
export def "chatupdate update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `chat:write`
  --as-user: string # Pass true to update the message as the authed user. [Bot users](/bot-users) in this context are considered authed users.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string. This field is required when not presenting `text`. If you don't include this field, the message's previous `attachments` will be retained. To remove previous `attachments`, include an empty array for this field.
  --blocks: string # A JSON-based array of [structured blocks](/block-kit/building), presented as a URL-encoded string. If you don't include this field, the message's previous `blocks` will be retained. To remove previous `blocks`, include an empty array for this field.
  channel: string # Channel containing the message to be updated.
  --link-names: string # Find and link channel names and usernames. Defaults to `none`. If you do not specify a value for this field, the original value set for the message will be overwritten with the default, `none`.
  --parse: string # Change how messages are treated. Defaults to `client`, unlike `chat.postMessage`. Accepts either `none` or `full`. If you do not specify a value for this field, the original value set for the message will be overwritten with the default, `client`.
  --text: string # New text for the message, using the [default formatting rules](/reference/surfaces/formatting). It's not required when presenting `blocks` or `attachments`.
  ts: string # Timestamp of the message to be updated.
]: any -> record<channel: string, message: record<attachments: list<record>, blocks: record, text: string>, ok: bool, text: string, ts: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.update")
  let body = {as_user: $as_user, attachments: $attachments, blocks: $blocks, channel: $channel, link_names: $link_names, parse: $parse, text: $text, ts: $ts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Archives a conversation.
#
# POST /conversations.archive
# Docs: https://api.slack.com/methods/conversations.archive — API method documentation
# operationId: conversations_archive
export def "conversationsarchive archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # ID of conversation to archive
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.archive")
  let body = {channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Closes a direct message or multi-person direct message.
#
# POST /conversations.close
# Docs: https://api.slack.com/methods/conversations.close — API method documentation
# operationId: conversations_close
export def "conversationsclose close" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # Conversation to close.
]: any -> record<already_closed: bool, no_op: bool, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.close")
  let body = {channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Initiates a public or private channel-based conversation
#
# POST /conversations.create
# Docs: https://api.slack.com/methods/conversations.create — API method documentation
# operationId: conversations_create
export def "conversationscreate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --name: string # Name of the public or private channel to create
  --is-private: oneof<nothing, bool> # Create a private channel instead of a public one
]: any -> record<channel: list<any>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.create")
  let body = {name: $name, is_private: $is_private} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetches a conversation's history of messages and events.
#
# GET /conversations.history
# Docs: https://api.slack.com/methods/conversations.history — API method documentation
# operationId: conversations_history
export def "conversationshistory history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `conversations:history`
  --channel: string # Conversation ID to fetch history for.
  --latest: float # End of time range of messages to include in results.
  --oldest: float # Start of time range of messages to include in results.
  --inclusive: oneof<nothing, bool> # Include messages with latest or oldest timestamp in results only when either timestamp is specified.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> record<channel_actions_count: int, channel_actions_ts: list<any>, has_more: bool, messages: table<attachments: list, blocks: list, bot_id: list, bot_profile: record, client_msg_id: string, comment: record, display_as_bot: bool, file: record, files: list, icons: record, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list, purpose: string, reactions: list, reply_count: int, reply_users: list, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record, user_team: string, username: string>, ok: bool, pin_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "latest" $latest "scalar") (serialize-qp "oldest" $oldest "scalar") (serialize-qp "inclusive" $inclusive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve information about a conversation.
#
# GET /conversations.info
# Docs: https://api.slack.com/methods/conversations.info — API method documentation
# operationId: conversations_info
export def "conversationsinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `conversations:read`
  --channel: string # Conversation ID to learn more about
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for this conversation. Defaults to `false`
  --include-num-members: oneof<nothing, bool> # Set to `true` to include the member count for the specified conversation. Defaults to `false`
]: nothing -> record<channel: list<any>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "include_locale" $include_locale "scalar") (serialize-qp "include_num_members" $include_num_members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invites users to a channel.
#
# POST /conversations.invite
# Docs: https://api.slack.com/methods/conversations.invite — API method documentation
# operationId: conversations_invite
export def "conversationsinvite invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # The ID of the public or private channel to invite user(s) to.
  --users: string # A comma separated list of user IDs. Up to 1000 users may be listed.
]: any -> record<channel: list<any>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.invite")
  let body = {channel: $channel, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Joins an existing conversation.
#
# POST /conversations.join
# Docs: https://api.slack.com/methods/conversations.join — API method documentation
# operationId: conversations_join
export def "conversationsjoin join" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `channels:write`
  --channel: string # ID of conversation to join
]: any -> record<channel: list<any>, ok: bool, response_metadata: record<warnings: list<string>>, warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.join")
  let body = {channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes a user from a conversation.
#
# POST /conversations.kick
# Docs: https://api.slack.com/methods/conversations.kick — API method documentation
# operationId: conversations_kick
export def "conversationskick kick" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # ID of conversation to remove user from.
  --user: string # User ID to be removed.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.kick")
  let body = {channel: $channel, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Leaves a conversation.
#
# POST /conversations.leave
# Docs: https://api.slack.com/methods/conversations.leave — API method documentation
# operationId: conversations_leave
export def "conversationsleave leave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # Conversation to leave
]: any -> record<not_in_channel: bool, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.leave")
  let body = {channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Lists all channels in a Slack team.
#
# GET /conversations.list
# Docs: https://api.slack.com/methods/conversations.list — API method documentation
# operationId: conversations_list
export def "conversationslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `conversations:read`
  --exclude-archived: oneof<nothing, bool> # Set to `true` to exclude archived channels from the list
  --types: string # Mix and match channel types by providing a comma-separated list of any combination of `public_channel`, `private_channel`, `mpim`, `im`
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached. Must be an integer no larger than 1000.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "exclude_archived" $exclude_archived "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets the read cursor in a channel.
#
# POST /conversations.mark
# Docs: https://api.slack.com/methods/conversations.mark — API method documentation
# operationId: conversations_mark
export def "conversationsmark mark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # Channel or conversation to set the read cursor for.
  --ts: float # Unique identifier of message you want marked as most recently seen in this conversation.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.mark")
  let body = {channel: $channel, ts: $ts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve members of a conversation.
#
# GET /conversations.members
# Docs: https://api.slack.com/methods/conversations.members — API method documentation
# operationId: conversations_members
export def "conversationsmembers members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `conversations:read`
  --channel: string # ID of the conversation to retrieve members for
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> record<members: list<string>, ok: bool, response_metadata: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Opens or resumes a direct message or multi-person direct message.
#
# POST /conversations.open
# Docs: https://api.slack.com/methods/conversations.open — API method documentation
# operationId: conversations_open
export def "conversationsopen open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # Resume a conversation by supplying an `im` or `mpim`'s ID. Or provide the `users` field instead.
  --users: string # Comma separated lists of users. If only one user is included, this creates a 1:1 DM.  The ordering of the users is preserved whenever a multi-person direct message is returned. Supply a `channel` when not supplying `users`.
  --return-im: oneof<nothing, bool> # Boolean, indicates you want the full IM channel definition in the response.
]: any -> record<already_open: bool, channel: list<any>, no_op: bool, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.open")
  let body = {channel: $channel, users: $users, return_im: $return_im} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Renames a conversation.
#
# POST /conversations.rename
# Docs: https://api.slack.com/methods/conversations.rename — API method documentation
# operationId: conversations_rename
export def "conversationsrename rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # ID of conversation to rename
  --name: string # New name for conversation.
]: any -> record<channel: list<any>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.rename")
  let body = {channel: $channel, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a thread of messages posted to a conversation
#
# GET /conversations.replies
# Docs: https://api.slack.com/methods/conversations.replies — API method documentation
# operationId: conversations_replies
export def "conversationsreplies replies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `conversations:history`
  --channel: string # Conversation ID to fetch thread from.
  --ts: float # Unique identifier of a thread's parent message. `ts` must be the timestamp of an existing message with 0 or more replies. If there are no replies then just the single message referenced by `ts` will return - it is just an ordinary, unthreaded message.
  --latest: float # End of time range of messages to include in results.
  --oldest: float # Start of time range of messages to include in results.
  --inclusive: oneof<nothing, bool> # Include messages with latest or oldest timestamp in results only when either timestamp is specified.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> record<has_more: bool, messages: list<list<any>>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "ts" $ts "scalar") (serialize-qp "latest" $latest "scalar") (serialize-qp "oldest" $oldest "scalar") (serialize-qp "inclusive" $inclusive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.replies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets the purpose for a conversation.
#
# POST /conversations.setPurpose
# Docs: https://api.slack.com/methods/conversations.setPurpose — API method documentation
# operationId: conversations_setPurpose
export def "conversationsset-purpose setPurpose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # Conversation to set the purpose of
  --purpose: string # A new, specialer purpose
]: any -> record<channel: list<any>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.setPurpose")
  let body = {channel: $channel, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Sets the topic for a conversation.
#
# POST /conversations.setTopic
# Docs: https://api.slack.com/methods/conversations.setTopic — API method documentation
# operationId: conversations_setTopic
export def "conversationsset-topic setTopic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # Conversation to set the topic of
  --topic: string # The new topic string. Does not support formatting or linkification.
]: any -> record<channel: list<any>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.setTopic")
  let body = {channel: $channel, topic: $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Reverses conversation archival.
#
# POST /conversations.unarchive
# Docs: https://api.slack.com/methods/conversations.unarchive — API method documentation
# operationId: conversations_unarchive
export def "conversationsunarchive unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `conversations:write`
  --channel: string # ID of conversation to unarchive
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.unarchive")
  let body = {channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Open a dialog with a user
#
# GET /dialog.open
# Docs: https://api.slack.com/methods/dialog.open — API method documentation
# operationId: dialog_open
export def "dialogopen open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dialog: string # The dialog definition. This must be a JSON-encoded string.
  --trigger-id: string # Exchange a trigger to post to the user.
  --hdr-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dialog" $dialog "scalar") (serialize-qp "trigger_id" $trigger_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dialog.open" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ends the current user's Do Not Disturb session immediately.
#
# POST /dnd.endDnd
# Docs: https://api.slack.com/methods/dnd.endDnd — API method documentation
# operationId: dnd_endDnd
export def "dndend-dnd endDnd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `dnd:write`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dnd.endDnd")
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ends the current user's snooze mode immediately.
#
# POST /dnd.endSnooze
# Docs: https://api.slack.com/methods/dnd.endSnooze — API method documentation
# operationId: dnd_endSnooze
export def "dndend-snooze endSnooze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `dnd:write`
]: nothing -> record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dnd.endSnooze")
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a user's current Do Not Disturb status.
#
# GET /dnd.info
# Docs: https://api.slack.com/methods/dnd.info — API method documentation
# operationId: dnd_info
export def "dndinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `dnd:read`
  --user: string # User to fetch status for (defaults to current user)
]: nothing -> record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dnd.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Turns on Do Not Disturb mode for the current user, or changes its duration.
#
# POST /dnd.setSnooze
# Docs: https://api.slack.com/methods/dnd.setSnooze — API method documentation
# operationId: dnd_setSnooze
export def "dndset-snooze setSnooze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `dnd:write`
  num_minutes: string # Number of minutes, from now, to snooze until.
]: any -> record<ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dnd.setSnooze")
  let body = {token: $body_token, num_minutes: $num_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieves the Do Not Disturb status for up to 50 users on a team.
#
# GET /dnd.teamInfo
# Docs: https://api.slack.com/methods/dnd.teamInfo — API method documentation
# operationId: dnd_teamInfo
export def "dndteam-info teamInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `dnd:read`
  --users: string # Comma-separated list of users to fetch Do Not Disturb status for
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "users" $users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dnd.teamInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists custom emoji for a team.
#
# GET /emoji.list
# Docs: https://api.slack.com/methods/emoji.list — API method documentation
# operationId: emoji_list
export def "emojilist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `emoji:read`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emoji.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an existing comment on a file.
#
# POST /files.comments.delete
# Docs: https://api.slack.com/methods/files.comments.delete — API method documentation
# operationId: files_comments_delete
export def "filescommentsdelete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `files:write:user`
  --file: string # File to delete a comment from.
  --id: string # The comment to delete.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.comments.delete")
  let body = {file: $file, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deletes a file.
#
# POST /files.delete
# Docs: https://api.slack.com/methods/files.delete — API method documentation
# operationId: files_delete
export def "filesdelete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `files:write:user`
  --file: string # ID of file to delete.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.delete")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets information about a file.
#
# GET /files.info
# Docs: https://api.slack.com/methods/files.info — API method documentation
# operationId: files_info
export def "filesinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `files:read`
  --file: string # Specify a file by providing its ID.
  --count: string
  --page: string
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
  --cursor: string # Parameter for pagination. File comments are paginated for a single file. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection of comments. See [pagination](/docs/pagination) for more details.
]: nothing -> record<comments: list<any>, content_html: any, editor: string, file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List for a team, in a channel, or from a user with applied filters.
#
# GET /files.list
# Docs: https://api.slack.com/methods/files.list — API method documentation
# operationId: files_list
export def "fileslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `files:read`
  --user: string # Filter files created by a single user.
  --channel: string # Filter files appearing in a specific channel, indicated by its ID.
  --ts-from: float # Filter files created after this timestamp (inclusive).
  --ts-to: float # Filter files created before this timestamp (inclusive).
  --types: string # Filter files by type ([see below](#file_types)). You can pass multiple values in the types argument, like `types=spaces,snippets`.The default value is `all`, which does not filter the list.
  --count: string
  --page: string
  --show-files-hidden-by-limit: oneof<nothing, bool> # Show truncated file info for files hidden due to being too old, and the team who owns the file being over the file limit.
]: nothing -> record<files: table<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "ts_from" $ts_from "scalar") (serialize-qp "ts_to" $ts_to "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "show_files_hidden_by_limit" $show_files_hidden_by_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a file from a remote service
#
# POST /files.remote.add
# Docs: https://api.slack.com/methods/files.remote.add — API method documentation
# operationId: files_remote_add
export def "filesremoteadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `remote_files:write`
  --external-id: string # Creator defined GUID for the file.
  --title: string # Title of the file being shared.
  --filetype: string # type of file
  --external-url: string # URL of the remote file.
  --preview-image: string # Preview of the document via `multipart/form-data`.
  --indexable-file-contents: string # A text file (txt, pdf, doc, etc.) containing textual search terms that are used to improve discovery of the remote file.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.remote.add")
  let body = {token: $body_token, external_id: $external_id, title: $title, filetype: $filetype, external_url: $external_url, preview_image: $preview_image, indexable_file_contents: $indexable_file_contents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve information about a remote file added to Slack
#
# GET /files.remote.info
# Docs: https://api.slack.com/methods/files.remote.info — API method documentation
# operationId: files_remote_info
export def "filesremoteinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `remote_files:read`
  --file: string # Specify a file by providing its ID.
  --external-id: string # Creator defined GUID for the file.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "external_id" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.remote.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve information about a remote file added to Slack
#
# GET /files.remote.list
# Docs: https://api.slack.com/methods/files.remote.list — API method documentation
# operationId: files_remote_list
export def "filesremotelist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `remote_files:read`
  --channel: string # Filter files appearing in a specific channel, indicated by its ID.
  --ts-from: float # Filter files created after this timestamp (inclusive).
  --ts-to: float # Filter files created before this timestamp (inclusive).
  --limit: int # The maximum number of items to return.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "ts_from" $ts_from "scalar") (serialize-qp "ts_to" $ts_to "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.remote.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a remote file.
#
# POST /files.remote.remove
# Docs: https://api.slack.com/methods/files.remote.remove — API method documentation
# operationId: files_remote_remove
export def "filesremoteremove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `remote_files:write`
  --file: string # Specify a file by providing its ID.
  --external-id: string # Creator defined GUID for the file.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.remote.remove")
  let body = {token: $body_token, file: $file, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Share a remote file into a channel.
#
# GET /files.remote.share
# Docs: https://api.slack.com/methods/files.remote.share — API method documentation
# operationId: files_remote_share
export def "filesremoteshare share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `remote_files:share`
  --file: string # Specify a file registered with Slack by providing its ID. Either this field or `external_id` or both are required.
  --external-id: string # The globally unique identifier (GUID) for the file, as set by the app registering the file with Slack.  Either this field or `file` or both are required.
  --channels: string # Comma-separated list of channel IDs where the file will be shared.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "channels" $channels "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.remote.share" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing remote file.
#
# POST /files.remote.update
# Docs: https://api.slack.com/methods/files.remote.update — API method documentation
# operationId: files_remote_update
export def "filesremoteupdate update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `remote_files:write`
  --file: string # Specify a file by providing its ID.
  --external-id: string # Creator defined GUID for the file.
  --title: string # Title of the file being shared.
  --filetype: string # type of file
  --external-url: string # URL of the remote file.
  --preview-image: string # Preview of the document via `multipart/form-data`.
  --indexable-file-contents: string # File containing contents that can be used to improve searchability for the remote file.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.remote.update")
  let body = {token: $body_token, file: $file, external_id: $external_id, title: $title, filetype: $filetype, external_url: $external_url, preview_image: $preview_image, indexable_file_contents: $indexable_file_contents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Revokes public/external sharing access for a file
#
# POST /files.revokePublicURL
# Docs: https://api.slack.com/methods/files.revokePublicURL — API method documentation
# operationId: files_revokePublicURL
export def "filesrevoke-public-url revokePublicURL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `files:write:user`
  --file: string # File to revoke
]: any -> record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.revokePublicURL")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enables a file for public/external sharing.
#
# POST /files.sharedPublicURL
# Docs: https://api.slack.com/methods/files.sharedPublicURL — API method documentation
# operationId: files_sharedPublicURL
export def "filesshared-public-url sharedPublicURL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `files:write:user`
  --file: string # File to share
]: any -> record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.sharedPublicURL")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Uploads or creates a file.
#
# POST /files.upload
# Docs: https://api.slack.com/methods/files.upload — API method documentation
# operationId: files_upload
export def "filesupload upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `files:write:user`
  --file: string # File contents via `multipart/form-data`. If omitting this parameter, you must submit `content`.
  --content: string # File contents via a POST variable. If omitting this parameter, you must provide a `file`.
  --filetype: string # A [file type](/types/file#file_types) identifier.
  --filename: string # Filename of file.
  --title: string # Title of file.
  --initial-comment: string # The message text introducing the file in specified `channels`.
  --channels: string # Comma-separated list of channel names or IDs where the file will be shared.
  --thread-ts: float # Provide another message's `ts` value to upload this file as a reply. Never use a reply's `ts` value; use its parent instead.
]: any -> record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.upload")
  let body = {token: $body_token, file: $file, content: $content, filetype: $filetype, filename: $filename, title: $title, initial_comment: $initial_comment, channels: $channels, thread_ts: $thread_ts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# For Enterprise Grid workspaces, map local user IDs to global user IDs
#
# GET /migration.exchange
# Docs: https://api.slack.com/methods/migration.exchange — API method documentation
# operationId: migration_exchange
export def "migrationexchange exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `tokens.basic`
  --users: string # A comma-separated list of user ids, up to 400 per request
  --team-id: string # Specify team_id starts with `T` in case of Org Token
  --to-old: oneof<nothing, bool> # Specify `true` to convert `W` global user IDs to workspace-specific `U` IDs. Defaults to `false`.
]: nothing -> record<enterprise_id: string, invalid_user_ids: list<string>, ok: bool, team_id: string, user_id_map: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "to_old" $to_old "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/migration.exchange" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchanges a temporary OAuth verifier code for an access token.
#
# GET /oauth.access
# Docs: https://api.slack.com/methods/oauth.access — API method documentation
# operationId: oauth_access
export def "oauthaccess access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback.
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
  --single-channel: oneof<nothing, bool> # Request the user to add your app only to a single channel. Only valid with a [legacy workspace app](https://api.slack.com/legacy-workspace-apps).
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "single_channel" $single_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth.access" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchanges a temporary OAuth verifier code for a workspace token.
#
# GET /oauth.token
# Docs: https://api.slack.com/methods/oauth.token — API method documentation
# operationId: oauth_token
export def "oauthtoken token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback.
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
  --single-channel: oneof<nothing, bool> # Request the user to add your app only to a single channel.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "single_channel" $single_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth.token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchanges a temporary OAuth verifier code for an access token.
#
# GET /oauth.v2.access
# Docs: https://api.slack.com/methods/oauth.v2.access — API method documentation
# operationId: oauth_v2_access
export def "oauthv2access access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback.
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth.v2.access" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pins an item to a channel.
#
# POST /pins.add
# Docs: https://api.slack.com/methods/pins.add — API method documentation
# operationId: pins_add
export def "pinsadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `pins:write`
  channel: string # Channel to pin the item in.
  --timestamp: string # Timestamp of the message to pin.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pins.add")
  let body = {channel: $channel, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Lists items pinned to a channel.
#
# GET /pins.list
# Docs: https://api.slack.com/methods/pins.list — API method documentation
# operationId: pins_list
export def "pinslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `pins:read`
  --channel: string # Channel to get pinned items for.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pins.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Un-pins an item from a channel.
#
# POST /pins.remove
# Docs: https://api.slack.com/methods/pins.remove — API method documentation
# operationId: pins_remove
export def "pinsremove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `pins:write`
  channel: string # Channel where the item is pinned to.
  --timestamp: string # Timestamp of the message to un-pin.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pins.remove")
  let body = {channel: $channel, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Adds a reaction to an item.
#
# POST /reactions.add
# Docs: https://api.slack.com/methods/reactions.add — API method documentation
# operationId: reactions_add
export def "reactionsadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `reactions:write`
  channel: string # Channel where the message to add reaction to was posted.
  name: string # Reaction (emoji) name.
  timestamp: string # Timestamp of the message to add reaction to.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reactions.add")
  let body = {channel: $channel, name: $name, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets reactions for an item.
#
# GET /reactions.get
# Docs: https://api.slack.com/methods/reactions.get — API method documentation
# operationId: reactions_get
export def "reactionsget get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `reactions:read`
  --channel: string # Channel where the message to get reactions for was posted.
  --file: string # File to get reactions for.
  --file-comment: string # File comment to get reactions for.
  --full: oneof<nothing, bool> # If true always return the complete reaction list.
  --timestamp: string # Timestamp of the message to get reactions for.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "file_comment" $file_comment "scalar") (serialize-qp "full" $full "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reactions.get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists reactions made by a user.
#
# GET /reactions.list
# Docs: https://api.slack.com/methods/reactions.list — API method documentation
# operationId: reactions_list
export def "reactionslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `reactions:read`
  --user: string # Show reactions made by this user. Defaults to the authed user.
  --full: oneof<nothing, bool> # If true always return the complete reaction list.
  --count: int
  --page: int
  --cursor: string # Parameter for pagination. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection. See [pagination](/docs/pagination) for more details.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
]: nothing -> record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "full" $full "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reactions.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes a reaction from an item.
#
# POST /reactions.remove
# Docs: https://api.slack.com/methods/reactions.remove — API method documentation
# operationId: reactions_remove
export def "reactionsremove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `reactions:write`
  name: string # Reaction (emoji) name.
  --file: string # File to remove reaction from.
  --file-comment: string # File comment to remove reaction from.
  --channel: string # Channel where the message to remove reaction from was posted.
  --timestamp: string # Timestamp of the message to remove reaction from.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reactions.remove")
  let body = {name: $name, file: $file, file_comment: $file_comment, channel: $channel, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Creates a reminder.
#
# POST /reminders.add
# Docs: https://api.slack.com/methods/reminders.add — API method documentation
# operationId: reminders_add
export def "remindersadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `reminders:write`
  text: string # The content of the reminder
  time: string # When this reminder should happen: the Unix timestamp (up to five years from now), the number of seconds until the reminder (if within 24 hours), or a natural language description (Ex. "in 15 minutes," or "every Thursday")
  --user: string # The user who will receive the reminder. If no user is specified, the reminder will go to user who created it.
]: any -> record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reminders.add")
  let body = {text: $text, time: $time, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Marks a reminder as complete.
#
# POST /reminders.complete
# Docs: https://api.slack.com/methods/reminders.complete — API method documentation
# operationId: reminders_complete
export def "reminderscomplete complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `reminders:write`
  --reminder: string # The ID of the reminder to be marked as complete
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reminders.complete")
  let body = {reminder: $reminder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deletes a reminder.
#
# POST /reminders.delete
# Docs: https://api.slack.com/methods/reminders.delete — API method documentation
# operationId: reminders_delete
export def "remindersdelete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `reminders:write`
  --reminder: string # The ID of the reminder
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reminders.delete")
  let body = {reminder: $reminder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets information about a reminder.
#
# GET /reminders.info
# Docs: https://api.slack.com/methods/reminders.info — API method documentation
# operationId: reminders_info
export def "remindersinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `reminders:read`
  --reminder: string # The ID of the reminder
]: nothing -> record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "reminder" $reminder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reminders.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all reminders created by or for a given user.
#
# GET /reminders.list
# Docs: https://api.slack.com/methods/reminders.list — API method documentation
# operationId: reminders_list
export def "reminderslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `reminders:read`
]: nothing -> record<ok: bool, reminders: table<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reminders.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts a Real Time Messaging session.
#
# GET /rtm.connect
# Docs: https://api.slack.com/methods/rtm.connect — API method documentation
# operationId: rtm_connect
export def "rtmconnect connect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `rtm:stream`
  --batch-presence-aware: oneof<nothing, bool> # Batch presence deliveries via subscription. Enabling changes the shape of `presence_change` events. See [batch presence](/docs/presence-and-status#batching).
  --presence-sub: oneof<nothing, bool> # Only deliver presence events when requested by subscription. See [presence subscriptions](/docs/presence-and-status#subscriptions).
]: nothing -> record<ok: bool, self: record<id: string, name: string>, team: record<domain: string, id: string, name: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "batch_presence_aware" $batch_presence_aware "scalar") (serialize-qp "presence_sub" $presence_sub "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rtm.connect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches for messages matching a query.
#
# GET /search.messages
# Docs: https://api.slack.com/methods/search.messages — API method documentation
# operationId: search_messages
export def "searchmessages messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `search:read`
  --count: int # Pass the number of results you want per "page". Maximum of `100`.
  --highlight: oneof<nothing, bool> # Pass a value of `true` to enable query highlight markers (see below).
  --page: int
  --qp-query: string # Search query.
  --qp-sort: string # Return matches sorted by either `score` or `timestamp`.
  --sort-dir: string # Change sort direction to ascending (`asc`) or descending (`desc`).
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "highlight" $highlight "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search.messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a star to an item.
#
# POST /stars.add
# Docs: https://api.slack.com/methods/stars.add — API method documentation
# operationId: stars_add
export def "starsadd add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `stars:write`
  --channel: string # Channel to add star to, or channel where the message to add star to was posted (used with `timestamp`).
  --file: string # File to add star to.
  --file-comment: string # File comment to add star to.
  --timestamp: string # Timestamp of the message to add star to.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stars.add")
  let body = {channel: $channel, file: $file, file_comment: $file_comment, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Lists stars for a user.
#
# GET /stars.list
# Docs: https://api.slack.com/methods/stars.list — API method documentation
# operationId: stars_list
export def "starslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `stars:read`
  --count: string
  --page: string
  --cursor: string # Parameter for pagination. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection. See [pagination](/docs/pagination) for more details.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
]: nothing -> record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stars.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes a star from an item.
#
# POST /stars.remove
# Docs: https://api.slack.com/methods/stars.remove — API method documentation
# operationId: stars_remove
export def "starsremove remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `stars:write`
  --channel: string # Channel to remove star from, or channel where the message to remove star from was posted (used with `timestamp`).
  --file: string # File to remove star from.
  --file-comment: string # File comment to remove star from.
  --timestamp: string # Timestamp of the message to remove star from.
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stars.remove")
  let body = {channel: $channel, file: $file, file_comment: $file_comment, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets the access logs for the current team.
#
# GET /team.accessLogs
# Docs: https://api.slack.com/methods/team.accessLogs — API method documentation
# operationId: team_accessLogs
export def "teamaccess-logs accessLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin`
  --before: string # End of time range of logs to include in results (inclusive).
  --count: string
  --page: string
]: nothing -> record<logins: table<count: int, country: string, date_first: int, date_last: int, ip: string, isp: string, region: string, user_agent: string, user_id: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.accessLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets billable users information for the current team.
#
# GET /team.billableInfo
# Docs: https://api.slack.com/methods/team.billableInfo — API method documentation
# operationId: team_billableInfo
export def "teambillable-info billableInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin`
  --user: string # A user to retrieve the billable information for. Defaults to all users.
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.billableInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the current team.
#
# GET /team.info
# Docs: https://api.slack.com/methods/team.info — API method documentation
# operationId: team_info
export def "teaminfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `team:read`
  --team: string # Team to get info on, if omitted, will return information about the current team. Will only return team that the authenticated token is allowed to see through external shared channels
]: nothing -> record<ok: bool, team: record<archived: bool, avatar_base_url: string, created: int, date_create: int, deleted: bool, description: string, discoverable: list<any>, domain: string, email_domain: string, enterprise_id: string, enterprise_name: string, external_org_migrations: record<current: list, date_updated: int>, has_compliance_export: bool, icon: record<image_102: string, image_132: string, image_230: string, image_34: string, image_44: string, image_68: string, image_88: string, image_default: bool>, id: string, is_assigned: bool, is_enterprise: int, is_over_storage_limit: bool, limit_ts: int, locale: string, messages_count: int, msg_edit_window_mins: int, name: string, over_integrations_limit: bool, over_storage_limit: bool, pay_prod_cur: string, plan: string, primary_owner: record<email: string, id: string>, sso_provider: record<label: string, name: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "team" $team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the integration logs for the current team.
#
# GET /team.integrationLogs
# Docs: https://api.slack.com/methods/team.integrationLogs — API method documentation
# operationId: team_integrationLogs
export def "teamintegration-logs integrationLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `admin`
  --app-id: string # Filter logs to this Slack app. Defaults to all logs.
  --change-type: string # Filter logs with this change type. Defaults to all logs.
  --count: string
  --page: string
  --service-id: string # Filter logs to this service. Defaults to all logs.
  --user: string # Filter logs generated by this user’s actions. Defaults to all logs.
]: nothing -> record<logs: table<admin_app_id: string, app_id: string, app_type: string, change_type: string, channel: string, date: string, scope: string, service_id: string, service_type: string, user_id: string, user_name: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "app_id" $app_id "scalar") (serialize-qp "change_type" $change_type "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.integrationLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a team's profile.
#
# GET /team.profile.get
# Docs: https://api.slack.com/methods/team.profile.get — API method documentation
# operationId: team_profile_get
export def "teamprofileget get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `users.profile:read`
  --visibility: string # Filter by visibility.
]: nothing -> record<ok: bool, profile: record<fields: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.profile.get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a User Group
#
# POST /usergroups.create
# Docs: https://api.slack.com/methods/usergroups.create — API method documentation
# operationId: usergroups_create
export def "usergroupscreate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write`
  --channels: string # A comma separated string of encoded channel IDs for which the User Group uses as a default.
  --description: string # A short description of the User Group.
  --handle: string # A mention handle. Must be unique among channels, users and User Groups.
  --include-count: oneof<nothing, bool> # Include the number of users in each User Group.
  name: string # A name for the User Group. Must be unique among User Groups.
]: any -> record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usergroups.create")
  let body = {channels: $channels, description: $description, handle: $handle, include_count: $include_count, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Disable an existing User Group
#
# POST /usergroups.disable
# Docs: https://api.slack.com/methods/usergroups.disable — API method documentation
# operationId: usergroups_disable
export def "usergroupsdisable disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write`
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to disable.
]: any -> record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usergroups.disable")
  let body = {include_count: $include_count, usergroup: $usergroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enable a User Group
#
# POST /usergroups.enable
# Docs: https://api.slack.com/methods/usergroups.enable — API method documentation
# operationId: usergroups_enable
export def "usergroupsenable enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write`
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to enable.
]: any -> record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usergroups.enable")
  let body = {include_count: $include_count, usergroup: $usergroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all User Groups for a team
#
# GET /usergroups.list
# Docs: https://api.slack.com/methods/usergroups.list — API method documentation
# operationId: usergroups_list
export def "usergroupslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-users: oneof<nothing, bool> # Include the list of users for each User Group.
  --qp-token: string # Authentication token. Requires scope: `usergroups:read`
  --include-count: oneof<nothing, bool> # Include the number of users in each User Group.
  --include-disabled: oneof<nothing, bool> # Include disabled User Groups.
]: nothing -> record<ok: bool, usergroups: table<auto_provision: bool, auto_type: list, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record, team_id: string, updated_by: string, user_count: int, users: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_users" $include_users "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "include_count" $include_count "scalar") (serialize-qp "include_disabled" $include_disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usergroups.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing User Group
#
# POST /usergroups.update
# Docs: https://api.slack.com/methods/usergroups.update — API method documentation
# operationId: usergroups_update
export def "usergroupsupdate update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write`
  --handle: string # A mention handle. Must be unique among channels, users and User Groups.
  --description: string # A short description of the User Group.
  --channels: string # A comma separated string of encoded channel IDs for which the User Group uses as a default.
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to update.
  --name: string # A name for the User Group. Must be unique among User Groups.
]: any -> record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usergroups.update")
  let body = {handle: $handle, description: $description, channels: $channels, include_count: $include_count, usergroup: $usergroup, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all users in a User Group
#
# GET /usergroups.users.list
# Docs: https://api.slack.com/methods/usergroups.users.list — API method documentation
# operationId: usergroups_users_list
export def "usergroupsuserslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `usergroups:read`
  --include-disabled: oneof<nothing, bool> # Allow results that involve disabled User Groups.
  --usergroup: string # The encoded ID of the User Group to update.
]: nothing -> record<ok: bool, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "include_disabled" $include_disabled "scalar") (serialize-qp "usergroup" $usergroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usergroups.users.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the list of users for a User Group
#
# POST /usergroups.users.update
# Docs: https://api.slack.com/methods/usergroups.users.update — API method documentation
# operationId: usergroups_users_update
export def "usergroupsusersupdate update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write`
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to update.
  users: string # A comma separated string of encoded user IDs that represent the entire list of users for the User Group.
]: any -> record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usergroups.users.update")
  let body = {include_count: $include_count, usergroup: $usergroup, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List conversations the calling user may access.
#
# GET /users.conversations
# Docs: https://api.slack.com/methods/users.conversations — API method documentation
# operationId: users_conversations
export def "usersconversations conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `conversations:read`
  --user: string # Browse conversations by a specific user ID's membership. Non-public channels are restricted to those where the calling user shares membership.
  --types: string # Mix and match channel types by providing a comma-separated list of any combination of `public_channel`, `private_channel`, `mpim`, `im`
  --exclude-archived: oneof<nothing, bool> # Set to `true` to exclude archived channels from the list
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached. Must be an integer no larger than 1000.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "exclude_archived" $exclude_archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the user profile photo
#
# POST /users.deletePhoto
# Docs: https://api.slack.com/methods/users.deletePhoto — API method documentation
# operationId: users_deletePhoto
export def "usersdelete-photo post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `users.profile:write`
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.deletePhoto")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets user presence information.
#
# GET /users.getPresence
# Docs: https://api.slack.com/methods/users.getPresence — API method documentation
# operationId: users_getPresence
export def "usersget-presence get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `users:read`
  --user: string # User to get presence info on. Defaults to the authed user.
]: nothing -> record<auto_away: bool, connection_count: int, last_activity: int, manual_away: bool, ok: bool, online: bool, presence: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.getPresence" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's identity.
#
# GET /users.identity
# Docs: https://api.slack.com/methods/users.identity — API method documentation
# operationId: users_identity
export def "usersidentity identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `identity.basic`
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.identity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a user.
#
# GET /users.info
# Docs: https://api.slack.com/methods/users.info — API method documentation
# operationId: users_info
export def "usersinfo info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `users:read`
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for this user. Defaults to `false`
  --user: string # User to get info on
]: nothing -> record<ok: bool, user: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "include_locale" $include_locale "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all users in a Slack team.
#
# GET /users.list
# Docs: https://api.slack.com/methods/users.list — API method documentation
# operationId: users_list
export def "userslist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `users:read`
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached. Providing no `limit` value will result in Slack attempting to deliver you the entire result set. If the collection is too large you may experience `limit_required` or HTTP 500 errors.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for users. Defaults to `false`
]: nothing -> record<cache_ts: int, members: list<list<any>>, ok: bool, response_metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "include_locale" $include_locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find a user with an email address.
#
# GET /users.lookupByEmail
# Docs: https://api.slack.com/methods/users.lookupByEmail — API method documentation
# operationId: users_lookupByEmail
export def "userslookup-by-email lookupByEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `users:read.email`
  --email: string # An email address belonging to a user in the workspace
]: nothing -> record<ok: bool, user: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.lookupByEmail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a user's profile information.
#
# GET /users.profile.get
# Docs: https://api.slack.com/methods/users.profile.get — API method documentation
# operationId: users_profile_get
export def "usersprofileget get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Authentication token. Requires scope: `users.profile:read`
  --include-labels: oneof<nothing, bool> # Include labels for each ID in custom profile fields
  --user: string # User to retrieve profile info for
]: nothing -> record<ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: record, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "include_labels" $include_labels "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.profile.get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the profile information for a user.
#
# POST /users.profile.set
# Docs: https://api.slack.com/methods/users.profile.set — API method documentation
# operationId: users_profile_set
export def "usersprofileset set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `users.profile:write`
  --name: string # Name of a single key to set. Usable only if `profile` is not passed.
  --profile: string # Collection of key:value pairs presented as a URL-encoded JSON hash. At most 50 fields may be set. Each field name is limited to 255 characters.
  --user: string # ID of user to change. This argument may only be specified by team admins on paid teams.
  --value: string # Value to set a single key to. Usable only if `profile` is not passed.
]: any -> record<email_pending: string, ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: record, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.profile.set")
  let body = {name: $name, profile: $profile, user: $user, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Marked a user as active. Deprecated and non-functional.
#
# POST /users.setActive
# Docs: https://api.slack.com/methods/users.setActive — API method documentation
# operationId: users_setActive
export def "usersset-active setActive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `users:write`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.setActive")
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the user profile photo
#
# POST /users.setPhoto
# Docs: https://api.slack.com/methods/users.setPhoto — API method documentation
# operationId: users_setPhoto
export def "usersset-photo setPhoto" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # Authentication token. Requires scope: `users.profile:write`
  --crop-w: string # Width/height of crop box (always square)
  --crop-x: string # X coordinate of top-left corner of crop box
  --crop-y: string # Y coordinate of top-left corner of crop box
  --image: string # File contents via `multipart/form-data`.
]: any -> record<ok: bool, profile: record<avatar_hash: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.setPhoto")
  let body = {token: $body_token, crop_w: $crop_w, crop_x: $crop_x, crop_y: $crop_y, image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Manually sets user presence.
#
# POST /users.setPresence
# Docs: https://api.slack.com/methods/users.setPresence — API method documentation
# operationId: users_setPresence
export def "usersset-presence setPresence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-token: string # Authentication token. Requires scope: `users:write`
  presence: string # Either `auto` or `away`
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.setPresence")
  let body = {presence: $presence} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Open a view for a user.
#
# GET /views.open
# Docs: https://api.slack.com/methods/views.open — API method documentation
# operationId: views_open
export def "viewsopen open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger-id: string # Exchange a trigger to post to the user.
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string.
  --hdr-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trigger_id" $trigger_id "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.open" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish a static view for a User.
#
# GET /views.publish
# Docs: https://api.slack.com/methods/views.publish — API method documentation
# operationId: views_publish
export def "viewspublish publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # `id` of the user you want publish a view to.
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string.
  --hash: string # A string that represents view state to protect against possible race conditions.
  --hdr-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.publish" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push a view onto the stack of a root view.
#
# GET /views.push
# Docs: https://api.slack.com/methods/views.push — API method documentation
# operationId: views_push
export def "viewspush push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger-id: string # Exchange a trigger to post to the user.
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string.
  --hdr-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trigger_id" $trigger_id "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.push" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing view.
#
# GET /views.update
# Docs: https://api.slack.com/methods/views.update — API method documentation
# operationId: views_update
export def "viewsupdate update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view-id: string # A unique identifier of the view to be updated. Either `view_id` or `external_id` is required.
  --external-id: string # A unique identifier of the view set by the developer. Must be unique for all views on a team. Max length of 255 characters. Either `view_id` or `external_id` is required.
  --view: string # A [view object](/reference/surfaces/views). This must be a JSON-encoded string.
  --hash: string # A string that represents view state to protect against possible race conditions.
  --hdr-token: string # Authentication token. Requires scope: `none`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view_id" $view_id "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.update" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Indicate that an app's step in a workflow completed execution.
#
# GET /workflows.stepCompleted
# Docs: https://api.slack.com/methods/workflows.stepCompleted — API method documentation
# operationId: workflows_stepCompleted
export def "workflowsstep-completed stepCompleted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workflow-step-execute-id: string # Context identifier that maps to the correct workflow step execution.
  --outputs: string # Key-value object of outputs from your step. Keys of this object reflect the configured `key` properties of your [`outputs`](/reference/workflows/workflow_step#output) array from your `workflow_step` object.
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_step_execute_id" $workflow_step_execute_id "scalar") (serialize-qp "outputs" $outputs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows.stepCompleted" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Indicate that an app's step in a workflow failed to execute.
#
# GET /workflows.stepFailed
# Docs: https://api.slack.com/methods/workflows.stepFailed — API method documentation
# operationId: workflows_stepFailed
export def "workflowsstep-failed stepFailed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workflow-step-execute-id: string # Context identifier that maps to the correct workflow step execution.
  --qp-error: string # A JSON-based object with a `message` property that should contain a human readable error message.
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_step_execute_id" $workflow_step_execute_id "scalar") (serialize-qp "error" $qp_error "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows.stepFailed" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the configuration for a workflow extension step.
#
# GET /workflows.updateStep
# Docs: https://api.slack.com/methods/workflows.updateStep — API method documentation
# operationId: workflows_updateStep
export def "workflowsupdate-step updateStep" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workflow-step-edit-id: string # A context identifier provided with `view_submission` payloads used to call back to `workflows.updateStep`.
  --inputs: string # A JSON key-value map of inputs required from a user during configuration. This is the data your app expects to receive when the workflow step starts. **Please note**: the embedded variable format is set and replaced by the workflow system. You cannot create custom variables that will be replaced at runtime. [Read more about variables in workflow steps here](/workflows/steps#variables).
  --outputs: string # An JSON array of output objects used during step execution. This is the data your app agrees to provide when your workflow step was executed.
  --step-name: string # An optional field that can be used to override the step name that is shown in the Workflow Builder.
  --step-image-url: string # An optional field that can be used to override app image that is shown in the Workflow Builder.
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute`
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_step_edit_id" $workflow_step_edit_id "scalar") (serialize-qp "inputs" $inputs "scalar") (serialize-qp "outputs" $outputs "scalar") (serialize-qp "step_name" $step_name "scalar") (serialize-qp "step_image_url" $step_image_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows.updateStep" $qp)
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
