# Auto-generated client for Zulip REST API v1.0.0
# Source: https://raw.githubusercontent.com/zulip/zulip/main/zerver/openapi/zulip.yaml
# Auth: --token flag or $env.ZULIP_REST_API_TOKEN

const BASE_URL = "https://example.zulipchat.com/api/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ZULIP_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://example.zulipchat.com/api/v1" "https:///api/v1" "https://chat.zulip.org/api/v1" "http://localhost:9991/api/v1" "http://{subdomain}.testserver/json"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def type-completer [] { ["channel" "direct" "private" "stream"] }
def op-completer [] { ["add" "remove"] }
def propagate-mode-completer [] { ["change_all" "change_later" "change_one"] }
def status-completer [] { ["active" "idle"] }
def include-subscribers-completer [] { ["false" "partial" "true"] }
def topics-policy-completer [] { ["allow_empty_topic" "disable_empty_topic" "empty_topic_only" "inherit"] }
def token-kind-completer [] { ["apns" "fcm"] }
def visibility-policy-completer [] { ["0" "1" "2" "3"] }
def web-mark-read-on-scroll-policy-completer [] { ["1" "2" "3"] }
def web-channel-default-view-completer [] { ["1" "2" "3" "4"] }
def color-scheme-completer [] { ["1" "2" "3"] }
def demote-inactive-streams-completer [] { ["1" "2" "3"] }
def user-list-style-completer [] { ["1" "2" "3"] }
def web-animate-image-previews-completer [] { ["always" "never" "on_hover"] }
def web-stream-unreads-count-display-policy-completer [] { ["1" "2" "3"] }
def desktop-icon-count-display-completer [] { ["1" "2" "3" "4"] }
def realm-name-in-email-notifications-policy-completer [] { ["1" "2" "3"] }
def automatically-follow-topics-policy-completer [] { ["1" "2" "3" "4"] }
def automatically-unmute-topics-in-muted-streams-policy-completer [] { ["1" "2" "3" "4"] }
def resolved-topic-notice-auto-read-policy-completer [] { ["always" "except_followed" "never"] }
def email-address-visibility-completer [] { ["1" "2" "3" "4" "5"] }
def property-completer [] { ["audible_notifications" "color" "desktop_notifications" "email_notifications" "in_home_view" "is_muted" "pin_to_top" "push_notifications" "wildcard_mentions_notify"] }
def export-type-completer [] { ["full_with_consent" "full_without_consent" "public"] }
def invite-as-completer [] { ["100" "200" "300" "400" "600"] }
def web-channel-default-view-completer-1 [] { ["1" "2" "4"] }
def type-completer-1 [] { ["channel" "direct" "stream"] }
def op-completer-1 [] { ["start" "stop"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "fetch-api-key fetch-api-key" } } | get name | first)
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

# Fetch an API key (production)
#
# POST /fetch_api_key
# operationId: fetch-api-key
export def "fetch-api-key fetch-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # The username to be used for authentication (typically, the email address, but depending on configuration, it could be an LDAP username).  See the `require_email_format_usernames` parameter documented in [GET /server_settings](/api/get-server-settings) for details.  (e.g. iago@zulip.com)
  password: string # The user's Zulip password (or LDAP password, if LDAP authentication is in use).  (e.g. abcd1234)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, api_key: string, email: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fetch_api_key")
  let body = {username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an API key (JWT)
#
# POST /jwt/fetch_api_key
# operationId: jwt-fetch-api-key
export def "jwt-fetch-api-key jwt-fetch-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # A JSON Web Token for the target user.  The token payload must contain a custom `email` claim with the target user's email address, e.g., `{"email": "<target user email>"}`.  (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImhhbWxldEB6dWxpcC5jb20ifQ.EsHxSVt54zPR-ywgPH54TB1FYmrGKsfq7hsQEhp_9w0)
  --include-profile: oneof<nothing, bool> # Whether to include a `user` object containing the target user's profile details in the response.  (default: false, e.g. false)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, api_key: string, email: string, user: record<user_id: any, delivery_email: any, email: any, full_name: any, date_joined: any, is_active: any, is_owner: any, is_admin: any, is_guest: any, is_bot: any, bot_type: any, bot_owner_id: any, role: any, timezone: any, avatar_url: any, avatar_version: any, is_imported_stub: any, is_deleted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jwt/fetch_api_key")
  let body = {token: $body_token, include_profile: $include_profile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an API key (development only)
#
# POST /dev_fetch_api_key
# operationId: dev-fetch-api-key
export def "dev-fetch-api-key dev-fetch-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # The email address for the user that owns the API key.  (e.g. iago@zulip.com)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, api_key: string, email: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dev_fetch_api_key")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List users (development only)
#
# GET /dev_list_users
# operationId: dev-list-users
export def "dev-list-users dev-list-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, direct_admins: table<email: string, realm_url: string>, direct_users: table<email: string, realm_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dev_list_users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get events from an event queue
#
# GET /events
# operationId: get-events
export def "events get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --queue-id: string # The ID of an event queue that was previously registered via `POST /api/v1/register` (see [Register a queue](/api/register-queue)).  (e.g. fb67bf8a-c031-47cc-84cf-ed80accacda8)
  --last-event-id: int # The highest event ID in this queue that you've received and wish to acknowledge. See the [code for `call_on_each_event`](https://github.com/zulip/python-zulip-api/blob/main/zulip/zulip/__init__.py) in the [zulip Python module](https://github.com/zulip/python-zulip-api) for an example implementation of correctly processing each event exactly once.  (e.g. -1)
  --dont-block: oneof<nothing, bool> # Set to `true` if the client is requesting a nonblocking reply. If not specified, the request will block until either a new event is available or a few minutes have passed, in which case the server will send the client a heartbeat event.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, events: list<any>, queue_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queue_id" $queue_id "scalar") (serialize-qp "last_event_id" $last_event_id "scalar") (serialize-qp "dont_block" $dont_block "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an event queue
#
# DELETE /events
# operationId: delete-queue
export def "events delete-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queue_id: string # The ID of an event queue that was previously registered via `POST /api/v1/register` (see [Register a queue](/api/register-queue)).  (e.g. fb67bf8a-c031-47cc-84cf-ed80accacda8)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events")
  let body = {queue_id: $queue_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get channel ID
#
# GET /get_stream_id
# operationId: get-stream-id
export def "get-stream-id get-stream-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream: string # The name of the channel to access.  (e.g. Denmark)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, stream_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/get_stream_id" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark all messages as read
#
# POST /mark_all_as_read
# DEPRECATED
# operationId: mark-all-as-read
@deprecated
export def "mark-all-as-read mark-all-as-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, complete: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mark_all_as_read")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark messages in a channel as read
#
# POST /mark_stream_as_read
# DEPRECATED
# operationId: mark-stream-as-read
@deprecated
export def "mark-stream-as-read mark-stream-as-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stream_id: int # The ID of the channel to access.  (e.g. 43)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mark_stream_as_read")
  let body = {stream_id: $stream_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Mark messages in a topic as read
#
# POST /mark_topic_as_read
# DEPRECATED
# operationId: mark-topic-as-read
@deprecated
export def "mark-topic-as-read mark-topic-as-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stream_id: int # The ID of the channel to access.  (e.g. 43)
  topic_name: string # The name of the topic whose messages should be marked as read.  Note: When the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  **Changes**: Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  (e.g. new coffee machine)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mark_topic_as_read")
  let body = {stream_id: $stream_id, topic_name: $topic_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get attachments
#
# GET /attachments
# operationId: get-attachments
export def "attachments get-attachments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, attachments: table<id: int, name: string, path_id: string, size: int, create_time: int, message_ids: list>, upload_space_used: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an attachment
#
# DELETE /attachments/{attachment_id}
# operationId: remove-attachment
export def "attachments remove-attachment" [
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a bot's stored data
#
# GET /bot_storage
# operationId: get-bot-storage
export def "bot-storage get-bot-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keys: string # A JSON-encoded list of keys for data in the bot's storage.  If not provided, then all data that's stored for the bot is returned.
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, storage: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bot_storage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a bot's stored data
#
# PUT /bot_storage
# operationId: update-bot-storage
export def "bot-storage update-bot-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  storage: record # A JSON-encoded dictionary mapping string keys to string values that will be added to the bot's storage.  If the bot's storage already has a specific key, then the value stored for that key will be updated for the new value.  (e.g. {foo: bar})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bot_storage")
  let body = {storage: $storage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a bot's stored data
#
# DELETE /bot_storage
# operationId: remove-bot-storage
export def "bot-storage remove-bot-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keys: list # A JSON-encoded list of keys to delete from the bot's storage.  If not provided, then all data that's stored for the bot is deleted.  (e.g. [foo])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bot_storage")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get drafts
#
# GET /drafts
# operationId: get-drafts
export def "drafts get-drafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, count: int, drafts: table<id: int, type: string, to: list, topic: string, content: string, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drafts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create drafts
#
# POST /drafts
# operationId: create-drafts
# --drafts item shape: {type: ""|"stream"|"private", to: list, topic: string, content: string, timestamp?: int}
export def "drafts create-drafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --drafts: list # A JSON-encoded list of containing new draft objects.  (e.g. [{type: stream, to: [1], topic: questions, content: What are the contribution guidelines for this project?, timestamp: 1595479019}]) — item shape: {type: ""|"stream"|"private", to: list, topic: string, content: string, timestamp?: int}
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, ids: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/drafts")
  let body = {drafts: $drafts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Edit a draft
#
# PATCH /drafts/{draft_id}
# operationId: edit-draft
export def "drafts edit-draft" [
  draft_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  draft: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/drafts/($draft_id)")
  let body = {draft: $draft} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a draft
#
# DELETE /drafts/{draft_id}
# operationId: delete-draft
export def "drafts delete-draft" [
  draft_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/drafts/($draft_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all navigation views
#
# GET /navigation_views
# operationId: get-navigation-views
export def "navigation-views get-navigation-views" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, navigation_views: table<fragment: string, is_pinned: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/navigation_views")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a navigation view
#
# POST /navigation_views
# operationId: add-navigation-view
export def "navigation-views add-navigation-view" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  fragment: string # A unique identifier for the view, used to determine navigation behavior when clicked.  Clients should use this value to navigate to the corresponding URL hash.  (e.g. narrow/is/alerted)
  --is-pinned: oneof<nothing, bool> # Determines whether the view appears directly in the sidebar or is hidden in the "More Views" menu.  - `true` - Pinned and visible in the sidebar. - `false` - Hidden and accessible via the "More Views" menu.  (e.g. true)
  --name: string # The user-facing name for custom navigation views. Omit this field for built-in views.  (nullable, e.g. Alert Words)
]: any -> record<result: any, msg: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/navigation_views")
  let body = {fragment: $fragment, is_pinned: $is_pinned, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update the navigation view
#
# PATCH /navigation_views/{fragment}
# operationId: edit-navigation-view
export def "navigation-views edit-navigation-view" [
  fragment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-pinned: oneof<nothing, bool> # Determines whether the view is pinned (true) or hidden in the menu (false).  (e.g. true)
  --name: string # The user-facing name for custom navigation views. Omit this field for built-in views.  (e.g. Watched Phrases)
]: any -> record<result: any, msg: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/navigation_views/($fragment)")
  let body = {is_pinned: $is_pinned, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a navigation view
#
# DELETE /navigation_views/{fragment}
# operationId: remove-navigation-view
export def "navigation-views remove-navigation-view" [
  fragment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/navigation_views/($fragment)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all saved snippets
#
# GET /saved_snippets
# operationId: get-saved-snippets
export def "saved-snippets get-saved-snippets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, saved_snippets: table<id: int, title: string, content: string, date_created: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saved_snippets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a saved snippet
#
# POST /saved_snippets
# operationId: create-saved-snippet
export def "saved-snippets create-saved-snippet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The title of the saved snippet.  (e.g. Example title)
  content: string # The content of the saved snippet in [Zulip-flavored Markdown](/help/format-your-message-using-markdown) format.  Clients should insert this content into a message when using a saved snippet.  (e.g. Welcome to the organization.)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, saved_snippet_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saved_snippets")
  let body = {title: $title, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Edit a saved snippet
#
# PATCH /saved_snippets/{saved_snippet_id}
# operationId: edit-saved-snippet
export def "saved-snippets edit-saved-snippet" [
  saved_snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the saved snippet.  (e.g. Welcome message)
  --content: string # The content of the saved snippet in the original [Zulip-flavored Markdown](/help/format-your-message-using-markdown) format.  Clients should insert this content into a message when using a saved snippet.  (e.g. Welcome to the organization.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_snippets/($saved_snippet_id)")
  let body = {title: $title, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a saved snippet
#
# DELETE /saved_snippets/{saved_snippet_id}
# operationId: delete-saved-snippet
export def "saved-snippets delete-saved-snippet" [
  saved_snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/saved_snippets/($saved_snippet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get reminders
#
# GET /reminders
# operationId: get-reminders
export def "reminders get-reminders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, reminders: table<reminder_id: int, type: string, to: list, content: string, rendered_content: string, scheduled_delivery_timestamp: int, failed: bool, reminder_target_message_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reminders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a message reminder
#
# POST /reminders
# operationId: create-message-reminder
export def "reminders create-message-reminder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message-id: int # The ID of the previously sent message to reference in the reminder message.  (e.g. 1)
  --scheduled-delivery-timestamp: int # The UNIX timestamp for when the reminder will be sent, in UTC seconds.  (e.g. 5681662420)
  --note: string # A note associated with the reminder shown in the Notification Bot message.  **Changes**: New in Zulip 11.0 (feature level 415).  (e.g. This is a reminder note.)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, reminder_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reminders")
  let body = {message_id: $message_id, scheduled_delivery_timestamp: $scheduled_delivery_timestamp, note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a reminder
#
# DELETE /reminders/{reminder_id}
# operationId: delete-reminder
export def "reminders delete-reminder" [
  reminder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reminders/($reminder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scheduled messages
#
# GET /scheduled_messages
# operationId: get-scheduled-messages
export def "scheduled-messages get-scheduled-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, scheduled_messages: table<scheduled_message_id: any, type: any, to: any, topic: any, content: any, rendered_content: any, scheduled_delivery_timestamp: any, failed: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scheduled_messages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a scheduled message
#
# POST /scheduled_messages
# operationId: create-scheduled-message
export def "scheduled-messages create-scheduled-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # The type of scheduled message to be sent. `"direct"` for a direct message and `"stream"` or `"channel"` for a channel message.  Note that, while `"private"` is supported for scheduling direct messages, clients are encouraged to use to the modern convention of `"direct"` to indicate this message type, because support for `"private"` may eventually be removed.  **Changes**: In Zulip 9.0 (feature level 248), `"channel"` was added as an additional value for this parameter to indicate the type of a channel message.  (e.g. direct)
  --body-to: any # The scheduled message's tentative target audience.  For channel messages, the integer ID of the channel. For direct messages, a list containing integer user IDs.  (e.g. [9, 10])
  content: string # The content of the message.  Clients should use the `max_message_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum message size.  (e.g. Hello)
  --topic: string # The topic of the message. Only required for channel messages (`"type": "stream"` or `"type": "channel"`), ignored otherwise.  Clients should use the `max_topic_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum topic length.  Note: When `"(no topic)"` or the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  When [topics are required](/help/require-topics), this parameter can't be `"(no topic)"`, an empty string, or the value of `realm_empty_topic_display_name`.  **Changes**: Before Zulip 10.0 (feature level 370), `"(no topic)"` was not interpreted as an empty string.  Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  (e.g. Castle)
  scheduled_delivery_timestamp: int # The UNIX timestamp for when the message will be sent, in UTC seconds.  (e.g. 3165826990)
  --read-by-sender: oneof<nothing, bool> # Whether the message should be initially marked read by its sender. If unspecified, the server uses a heuristic based on the client name and the recipient.  **Changes**: New in Zulip 8.0 (feature level 236).  (e.g. true)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, scheduled_message_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scheduled_messages")
  let body = {type: $type, to: $body_to, content: $content, topic: $topic, scheduled_delivery_timestamp: $scheduled_delivery_timestamp, read_by_sender: $read_by_sender} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Edit a scheduled message
#
# PATCH /scheduled_messages/{scheduled_message_id}
# operationId: update-scheduled-message
export def "scheduled-messages update-scheduled-message" [
  scheduled_message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # The type of scheduled message to be sent. `"direct"` for a direct message and `"stream"` or `"channel"` for a channel message.  When updating the type of the scheduled message, the `to` parameter is required. And, if updating the type of the scheduled message to `"stream"`/`"channel"`, then the `topic` parameter is also required.  Note that, while `"private"` is supported for scheduling direct messages, clients are encouraged to use to the modern convention of `"direct"` to indicate this message type, because support for `"private"` may eventually be removed.  **Changes**: In Zulip 9.0 (feature level 248), `"channel"` was added as an additional value for this parameter to indicate the type of a channel message.  (e.g. stream)
  --body-to: any # The scheduled message's tentative target audience.  For channel messages, the integer ID of the channel. For direct messages, a list containing integer user IDs.  Required when updating the `type` of the scheduled message.  (e.g. 11)
  --content: string # The updated content of the scheduled message.  Clients should use the `max_message_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum message size.  (e.g. Hello)
  --topic: string # The updated topic of the scheduled message.  Required when updating the `type` of the scheduled message to `"stream"` or `"channel"`. Ignored when the existing or updated `type` of the scheduled message is `"direct"` (or `"private"`).  Clients should use the `max_topic_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum topic length.  Note: When `"(no topic)"` or the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  When [topics are required](/help/require-topics), this parameter can't be `"(no topic)"`, an empty string, or the value of `realm_empty_topic_display_name`.  **Changes**: Before Zulip 10.0 (feature level 370), `"(no topic)"` was not interpreted as an empty string.  Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  (e.g. Castle)
  --scheduled-delivery-timestamp: int # The UNIX timestamp for when the message will be sent, in UTC seconds.  Required when updating a scheduled message that the server has already tried and failed to send. This state is indicated with `"failed": true` in `scheduled_messages` objects; see response description at [`GET /scheduled_messages`](/api/get-scheduled-messages#response).  (e.g. 3165826990)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scheduled_messages/($scheduled_message_id)")
  let body = {type: $type, to: $body_to, content: $content, topic: $topic, scheduled_delivery_timestamp: $scheduled_delivery_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a scheduled message
#
# DELETE /scheduled_messages/{scheduled_message_id}
# operationId: delete-scheduled-message
export def "scheduled-messages delete-scheduled-message" [
  scheduled_message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scheduled_messages/($scheduled_message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a default channel
#
# POST /default_streams
# operationId: add-default-stream
export def "default-streams add-default-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stream_id: int # The ID of the target channel.  (e.g. 10)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/default_streams")
  let body = {stream_id: $stream_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a default channel
#
# DELETE /default_streams
# operationId: remove-default-stream
export def "default-streams remove-default-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stream_id: int # The ID of the target channel.  (e.g. 10)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/default_streams")
  let body = {stream_id: $stream_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get messages
#
# GET /messages
# operationId: get-messages
@deprecated --flag use-first-unread-anchor
export def "messages get-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anchor: string # Integer message ID to anchor fetching of new messages. Supports special string values for when the client wants the server to compute the anchor to use:  - `newest`: The most recent message. - `oldest`: The oldest message. - `first_unread`: The oldest unread message matching the   query, if any; otherwise, the most recent message. - `date`: The first message on or after the datetime indicated by the   [`anchor_date`](#parameter-anchor_date), if any; otherwise, the most   recent message.  **Changes**: The `date` value is new in Zulip 12.0 (feature level 445).  String values are new in Zulip 3.0 (feature level 1). The `first_unread` functionality was supported in Zulip 2.1.x and older by not sending `anchor` and using `use_first_unread_anchor`.  In Zulip 2.1.x and older, `oldest` can be emulated with `"anchor": 0`, and `newest` with `"anchor": 10000000000000000` (that specific large value works around a bug in Zulip 2.1.x and older in the `found_newest` return value).  (e.g. 43)
  --include-anchor: oneof<nothing, bool> # Whether a message with the specified ID matching the narrow should be included.  **Changes**: New in Zulip 6.0 (feature level 155).  (default: true, e.g. false)
  --anchor-date: string # The date or datetime to use for finding the anchor message when `anchor` is `date`. Accepted formats include ISO 8601 date-only strings (e.g. `2005-04-18`) as well as full datetime strings (e.g. `2005-04-18T12:34:56Z`). If only a date is provided, the datetime is set to midnight (00:00) on that day in UTC. If no timezone is provided, UTC is assumed.  **Changes**: New in Zulip 12.0 (feature level 445).  (e.g. 2005-04-18T12:34:56Z)
  --num-before: int # The number of messages with IDs less than the anchor to retrieve. Required if `message_ids` is not provided.  (e.g. 4)
  --num-after: int # The number of messages with IDs greater than the anchor to retrieve. Required if `message_ids` is not provided.  (e.g. 8)
  --narrow: string # The narrow where you want to fetch the messages from. See how to [construct a narrow](/api/construct-narrow).  Note that many narrows, including all that lack a `channel`, `channels`, `stream`, or `streams` operator, search the user's personal message history. See [searching shared history](/help/search-for-messages#search-shared-history) for details.  For example, if you would like to fetch messages from all public channels instead of only the user's message history, then a specific narrow for messages sent to all public channels can be used: `{"operator": "channels", "operand": "public"}`.  Newly created bot users are not usually subscribed to any channels, so bots using this API should either be subscribed to appropriate channels or use a shared history search narrow with this endpoint.  **Changes**: See [changes section](/api/construct-narrow#changes) of search/narrow filter documentation.
  --client-gravatar: oneof<nothing, bool> # Whether the client supports computing gravatars URLs. If enabled, `avatar_url` will be included in the response only if there is a Zulip avatar, and will be `null` for users who are using gravatar as their avatar. This option significantly reduces the compressed size of user data, since gravatar URLs are long, random strings and thus do not compress well. The `client_gravatar` field is set to `true` if clients can compute their own gravatars.  **Changes**: The default value of this parameter was `false` prior to Zulip 5.0 (feature level 92).  (default: true, e.g. false)
  --apply-markdown: oneof<nothing, bool> # If `true`, message content is returned in the rendered HTML format. If `false`, message content is returned in the raw Markdown-format text that user entered.  See [Markdown message formatting](/api/message-formatting) for details on Zulip's HTML format.  (default: true, e.g. false)
  --use-first-unread-anchor: oneof<nothing, bool> # Legacy way to specify `"anchor": "first_unread"` in Zulip 2.1.x and older.  Whether to use the (computed by the server) first unread message matching the narrow as the `anchor`. Mutually exclusive with `anchor`.  **Changes**: Deprecated in Zulip 3.0 (feature level 1) and replaced by `"anchor": "first_unread"`.  (DEPRECATED, default: false, e.g. true)
  --message-ids: string # A list of message IDs to fetch. The server will return messages corresponding to the subset of the requested message IDs that exist and the current user has access to, potentially filtered by the narrow (if that parameter is provided).  It is an error to pass this parameter as well as any of the parameters involved in specifying a range of messages: `anchor`, `include_anchor`, `use_first_unread_anchor`, `num_before`, and `num_after`.  **Changes**: New in Zulip 10.0 (feature level 300). Previously, there was no way to request a specific set of messages IDs.
  --allow-empty-topic-name: oneof<nothing, bool> # Whether the client supports processing the empty string as a topic in the topic name fields in the returned data, including in returned edit_history data.  If `false`, the server will use the value of `realm_empty_topic_display_name` found in the [`POST /register`](/api/register-queue) response instead of empty string to represent the empty string topic in its response.  **Changes**: New in Zulip 10.0 (feature level 334). Previously, the empty string was not a valid topic.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, anchor: int, found_newest: bool, found_oldest: bool, found_anchor: bool, history_limited: bool, messages: table<avatar_url: any, client: any, content: any, content_type: any, display_recipient: any, edit_history: any, id: any, is_me_message: any, last_edit_timestamp: any, last_moved_timestamp: any, reactions: any, recipient_id: any, sender_email: any, sender_full_name: any, sender_id: any, sender_realm_str: any, stream_id: any, subject: any, submessages: any, timestamp: any, topic_links: any, type: any, flags: list, match_content: string, match_subject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "anchor" $anchor "scalar") (serialize-qp "include_anchor" $include_anchor "scalar") (serialize-qp "anchor_date" $anchor_date "scalar") (serialize-qp "num_before" $num_before "scalar") (serialize-qp "num_after" $num_after "scalar") (serialize-qp "narrow" $narrow "scalar") (serialize-qp "client_gravatar" $client_gravatar "scalar") (serialize-qp "apply_markdown" $apply_markdown "scalar") (serialize-qp "use_first_unread_anchor" $use_first_unread_anchor "scalar") (serialize-qp "message_ids" $message_ids "scalar") (serialize-qp "allow_empty_topic_name" $allow_empty_topic_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a message
#
# POST /messages
# operationId: send-message
export def "messages send-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # The type of message to be sent.  `"direct"` for a direct message and `"stream"` or `"channel"` for a channel message.  **Changes**: In Zulip 9.0 (feature level 248), `"channel"` was added as an additional value for this parameter to request a channel message.  In Zulip 7.0 (feature level 174), `"direct"` was added as the preferred way to request a direct message, deprecating the original `"private"`. While `"private"` is still supported for requesting direct messages, clients are encouraged to use to the modern convention with servers that support it, because support for `"private"` will eventually be removed.  (e.g. direct)
  --body-to: any # The channel or users receiving the message.  For channel messages, this is either the name or integer ID of the channel.  For direct messages, this is either a list containing integer user IDs or a list containing string Zulip API email addresses. The ID or email address of the user sending the message can be included in the list, but will be ignored by the server, unless the user sending the message is the only recipient of the message.  **Changes**: In Zulip 2.0.0, support for using user/channel IDs was added.  (e.g. [9, 10])
  content: string # The content of the message.  Clients should use the `max_message_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum message size.  (e.g. Hello)
  --topic: string # The topic of the message. Only required for channel messages (`"type": "stream"` or `"type": "channel"`), ignored otherwise.  Clients should use the `max_topic_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum topic length.  Note: When `"(no topic)"` or the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  When [topics are required](/help/require-topics), this parameter can't be `"(no topic)"`, an empty string, or the value of `realm_empty_topic_display_name`.  **Changes**: Before Zulip 10.0 (feature level 370), `"(no topic)"` was not interpreted as an empty string.  Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  New in Zulip 2.0.0. Previous Zulip releases encoded this as `subject`, which is currently a deprecated alias.  (e.g. Castle)
  --queue-id: string # For clients supporting [local echo](https://zulip.readthedocs.io/en/latest/subsystems/sending-messages.html#local-echo), the [event queue](/api/register-queue) ID for the client.  If passed, `local_id` is required.  If the message is successfully sent, the server will include `local_message_id` in the [`message` event](/api/get-events#message) that the client with this `queue_id` will receive.  (e.g. fb67bf8a-c031-47cc-84cf-ed80accacda8)
  --local-id: string # For clients supporting [local echo](https://zulip.readthedocs.io/en/latest/subsystems/sending-messages.html#local-echo), a unique string-format identifier chosen freely by the client.  If passed, `queue_id` is required.  If the message is successfully sent, the server will pass it back to the client without inspecting it as `local_message_id` in the [`message` event](/api/get-events#message) that the client with the above `queue_id` will receive.  (e.g. 100.01)
  --read-by-sender: oneof<nothing, bool> # Whether the message should be initially marked read by its sender. If unspecified, the server uses a heuristic based on the client name.  **Changes**: New in Zulip 8.0 (feature level 236).  (e.g. true)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, id: int, automatic_new_visibility_policy: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages")
  let body = {type: $type, to: $body_to, content: $content, topic: $topic, queue_id: $queue_id, local_id: $local_id, read_by_sender: $read_by_sender} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a message's edit history
#
# GET /messages/{message_id}/history
# operationId: get-message-history
export def "messages-history get-message-history" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-empty-topic-name: oneof<nothing, bool> # Whether the topic names i.e. `topic` and `prev_topic` fields in the `message_history` objects returned can be empty string.  If `false`, the value of `realm_empty_topic_display_name` found in the [`POST /register`](/api/register-queue) response is returned replacing the empty string as the topic name.  **Changes**: New in Zulip 10.0 (feature level 334).  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, message_history: table<topic: string, prev_topic: string, stream: int, prev_stream: int, content: string, rendered_content: string, prev_content: string, prev_rendered_content: string, user_id: int, content_html_diff: string, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allow_empty_topic_name" $allow_empty_topic_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/messages/($message_id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update personal message flags
#
# POST /messages/flags
# operationId: update-message-flags
export def "messages-flags update-message-flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # An array containing the IDs of the target messages.  (e.g. [4, 8, 15])
  op: string@op-completer # Whether to `add` the flag or `remove` it.  (e.g. add)
  flag: string # The flag that should be added/removed.  (e.g. read)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, messages: list<int>, ignored_because_not_subscribed_channels: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/flags")
  let body = {messages: $messages, op: $op, flag: $flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update personal message flags for narrow
#
# POST /messages/flags/narrow
# operationId: update-message-flags-for-narrow
export def "messages-flags-narrow update-message-flags-for-narrow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  anchor: any
  --include-anchor: oneof<nothing, bool> # Whether a message with the specified ID matching the narrow should be included in the update range.  (default: true, e.g. false)
  num_before: int # Limit the number of messages preceding the anchor in the update range. The server may decrease this to bound transaction sizes.  (e.g. 4)
  num_after: int # Limit the number of messages following the anchor in the update range. The server may decrease this to bound transaction sizes.  (e.g. 8)
  narrow: list # The narrow you want update flags within. See how to [construct a narrow](/api/construct-narrow).  Note that, when adding the `read` flag to messages, clients should consider including a narrow with the `is:unread` filter as an optimization. Including that filter takes advantage of the fact that the server has a database index for unread messages.  **Changes**: See [changes section](/api/construct-narrow#changes) of search/narrow filter documentation.  (default: [], e.g. [{operand: Denmark, operator: channel}])
  op: string@op-completer # Whether to `add` the flag or `remove` it.  (e.g. add)
  flag: string # The flag that should be added/removed. See [available flags](/api/update-message-flags#available-flags).  (e.g. read)
]: any -> record<result: any, msg: any, processed_count: int, updated_count: int, first_processed_id: int, last_processed_id: int, found_oldest: bool, found_newest: bool, ignored_because_not_subscribed_channels: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/flags/narrow")
  let body = {anchor: $anchor, include_anchor: $include_anchor, num_before: $num_before, num_after: $num_after, narrow: $narrow, op: $op, flag: $flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Render a message
#
# POST /messages/render
# operationId: render-message
export def "messages-render render-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The content of the message.  Clients should use the `max_message_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum message size.  (e.g. Hello)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, rendered: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/render")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add an emoji reaction
#
# POST /messages/{message_id}/reactions
# operationId: add-reaction
export def "messages-reactions add-reaction" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  emoji_name: string # The target emoji's human-readable name.  To find an emoji's name, hover over a message to reveal three icons on the right, then click the smiley face icon. Images of available reaction emojis appear. Hover over the emoji you want, and note that emoji's text name.  (e.g. octopus)
  --emoji-code: string # A unique identifier, defining the specific emoji codepoint requested, within the namespace of the `reaction_type`.  For most API clients, you won't need this, but it's important for Zulip apps to handle rare corner cases when adding/removing votes on an emoji reaction added previously by another user.  If the existing reaction was added when the Zulip server was using a previous version of the emoji data mapping between Unicode codepoints and human-readable names, sending the `emoji_code` in the data for the original reaction allows the Zulip server to correctly interpret your upvote as an upvote rather than a reaction with a "different" emoji.  (e.g. 1f419)
  --reaction-type: string # A string indicating the type of emoji. Each emoji `reaction_type` has an independent namespace for values of `emoji_code`.  If an API client is adding/removing a vote on an existing reaction, it should pass this parameter using the value the server provided for the existing reaction for specificity. Supported values:  - `unicode_emoji` : In this namespace, `emoji_code` will be a   dash-separated hex encoding of the sequence of Unicode codepoints   that define this emoji in the Unicode specification.  - `realm_emoji` : In this namespace, `emoji_code` will be the ID of   the uploaded [custom emoji](/help/custom-emoji).  - `zulip_extra_emoji` : These are special emoji included with Zulip.   In this namespace, `emoji_code` will be the name of the emoji (e.g.   "zulip").  **Changes**: In Zulip 3.0 (feature level 2), this parameter became optional for [custom emoji](/help/custom-emoji); previously, this endpoint assumed `unicode_emoji` if this parameter was not specified.  (e.g. unicode_emoji)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($message_id)/reactions")
  let body = {emoji_name: $emoji_name, emoji_code: $emoji_code, reaction_type: $reaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an emoji reaction
#
# DELETE /messages/{message_id}/reactions
# operationId: remove-reaction
export def "messages-reactions remove-reaction" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emoji-name: string # The target emoji's human-readable name.  To find an emoji's name, hover over a message to reveal three icons on the right, then click the smiley face icon. Images of available reaction emojis appear. Hover over the emoji you want, and note that emoji's text name.  (e.g. octopus)
  --emoji-code: string # A unique identifier, defining the specific emoji codepoint requested, within the namespace of the `reaction_type`.  For most API clients, you won't need this, but it's important for Zulip apps to handle rare corner cases when adding/removing votes on an emoji reaction added previously by another user.  If the existing reaction was added when the Zulip server was using a previous version of the emoji data mapping between Unicode codepoints and human-readable names, sending the `emoji_code` in the data for the original reaction allows the Zulip server to correctly interpret your upvote as an upvote rather than a reaction with a "different" emoji.  (e.g. 1f419)
  --reaction-type: string # A string indicating the type of emoji. Each emoji `reaction_type` has an independent namespace for values of `emoji_code`.  If an API client is adding/removing a vote on an existing reaction, it should pass this parameter using the value the server provided for the existing reaction for specificity. Supported values:  - `unicode_emoji` : In this namespace, `emoji_code` will be a   dash-separated hex encoding of the sequence of Unicode codepoints   that define this emoji in the Unicode specification.  - `realm_emoji` : In this namespace, `emoji_code` will be the ID of   the uploaded [custom emoji](/help/custom-emoji).  - `zulip_extra_emoji` : These are special emoji included with Zulip.   In this namespace, `emoji_code` will be the name of the emoji (e.g.   "zulip").  **Changes**: In Zulip 3.0 (feature level 2), this parameter became optional for [custom emoji](/help/custom-emoji); previously, this endpoint assumed `unicode_emoji` if this parameter was not specified.  (e.g. unicode_emoji)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($message_id)/reactions")
  let body = {emoji_name: $emoji_name, emoji_code: $emoji_code, reaction_type: $reaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a message's read receipts
#
# GET /messages/{message_id}/read_receipts
# operationId: get-read-receipts
export def "messages-read-receipts get-read-receipts" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, user_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($message_id)/read_receipts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if messages match a narrow
#
# GET /messages/matches_narrow
# operationId: check-messages-match-narrow
export def "messages-matches-narrow check-messages-match-narrow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --msg-ids: string # List of IDs for the messages to check.
  --narrow: string # A structure defining the narrow to check against. See how to [construct a narrow](/api/construct-narrow).  **Changes**: See [changes section](/api/construct-narrow#changes) of search/narrow filter documentation.
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, messages: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "msg_ids" $msg_ids "scalar") (serialize-qp "narrow" $narrow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/matches_narrow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a single message
#
# GET /messages/{message_id}
# operationId: get-message
export def "messages get-message" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apply-markdown: oneof<nothing, bool> # If `true`, message content is returned in the rendered HTML format. If `false`, message content is returned in the raw [Zulip-flavored Markdown format](/help/format-your-message-using-markdown) text that user entered.  **Changes**: New in Zulip 5.0 (feature level 120).  (default: true, e.g. false)
  --allow-empty-topic-name: oneof<nothing, bool> # Whether the client supports processing the empty string as a topic in the topic name fields in the returned data, including in returned edit_history data.  If `false`, the server will use the value of `realm_empty_topic_display_name` found in the [`POST /register`](/api/register-queue) response instead of empty string to represent the empty string topic in its response.  **Changes**: New in Zulip 10.0 (feature level 334). Previously, the empty string was not a valid topic.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, raw_content: string, message: record<avatar_url: any, client: any, content: any, content_type: any, display_recipient: any, edit_history: any, id: any, is_me_message: any, last_edit_timestamp: any, last_moved_timestamp: any, reactions: any, recipient_id: any, sender_email: any, sender_full_name: any, sender_id: any, sender_realm_str: any, stream_id: any, subject: any, submessages: any, timestamp: any, topic_links: any, type: any, flags: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apply_markdown" $apply_markdown "scalar") (serialize-qp "allow_empty_topic_name" $allow_empty_topic_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/messages/($message_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a message
#
# PATCH /messages/{message_id}
# operationId: update-message
export def "messages update-message" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --topic: string # The topic to move the message(s) to, to request changing the topic.  Clients should use the `max_topic_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum topic length  Should only be sent when changing the topic, and will throw an error if the target message is not a channel message.  Note: When the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  When [topics are required](/help/require-topics), this parameter can't be `"(no topic)"`, an empty string, or the value of `realm_empty_topic_display_name`.  You can [resolve topics](/help/resolve-a-topic) by editing the topic to `✔ {original_topic}` with the `propagate_mode` parameter set to `"change_all"`. The empty string topic cannot be marked as resolved.  **Changes**: Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  New in Zulip 2.0.0. Previous Zulip releases encoded this as `subject`, which is currently a deprecated alias.  (e.g. Castle)
  --propagate-mode: string@propagate-mode-completer # Which message(s) should be edited:  - `"change_later"`: The target message and all following messages. - `"change_one"`: Only the target message. - `"change_all"`: All messages in this topic.  Only the default value of `"change_one"` is valid when editing only the content of a message.  This parameter determines both which messages get moved and also whether clients that are currently narrowed to the topic containing the message should navigate or adjust their compose box recipient to point to the post-edit channel/topic.  (default: change_one, e.g. change_all)
  --send-notification-to-old-thread: oneof<nothing, bool> # Whether to send an automated message to the old topic to notify users where the messages were moved to.  **Changes**: Before Zulip 6.0 (feature level 152), this parameter had a default of `true` and was ignored unless the channel was changed.  New in Zulip 3.0 (feature level 9).  (default: false, e.g. true)
  --send-notification-to-new-thread: oneof<nothing, bool> # Whether to send an automated message to the new topic to notify users where the messages came from.  If the move is just [resolving/unresolving a topic](/help/resolve-a-topic), this parameter will not trigger an additional notification.  **Changes**: Before Zulip 6.0 (feature level 152), this parameter was ignored unless the channel was changed.  New in Zulip 3.0 (feature level 9).  (default: true, e.g. true)
  --content: string # The updated content of the target message.  Clients should use the `max_message_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum message size.  Note that a message's content and channel cannot be changed at the same time, so sending both `content` and `stream_id` parameters will throw an error.  (e.g. Hello)
  --prev-content-sha256: string # An optional SHA-256 hash of the previous raw content of the message that the client has at the time of the request.  If provided, the server will return an error if it does not match the SHA-256 hash of the message's content stored in the database.  Clients can use this feature to prevent races where multiple clients save conflicting edits to a message.  **Changes**: New in Zulip 11.0 (feature level 379).  (e.g. 6ae8a75555209fd6c44157c0aed8016e763ff435a19cf186f76863140143ff72)
  --stream-id: int # The channel ID to move the message(s) to, to request moving messages to another channel.  Should only be sent when changing the channel, and will throw an error if the target message is not a channel message.  Note that a message's content and channel cannot be changed at the same time, so sending both `content` and `stream_id` parameters will throw an error.  **Changes**: New in Zulip 3.0 (feature level 1).  (e.g. 43)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, detached_uploads: table<id: int, name: string, path_id: string, size: int, create_time: int, message_ids: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($message_id)")
  let body = {topic: $topic, propagate_mode: $propagate_mode, send_notification_to_old_thread: $send_notification_to_old_thread, send_notification_to_new_thread: $send_notification_to_new_thread, content: $content, prev_content_sha256: $prev_content_sha256, stream_id: $stream_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a message
#
# DELETE /messages/{message_id}
# operationId: delete-message
export def "messages delete-message" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Report a message
#
# POST /messages/{message_id}/report
# operationId: report-message
export def "messages-report report-message" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  report_type: string # The reason that best describes why the current user is reporting the target message for moderation.  Must be one of the `key` values in the `server_report_message_types` field in the [`POST /register`](/api/register-queue) response.  **Changes**: Prior to Zulip 12.0 (feature level 435), the allowed values for this parameter were limited to: `"harassment"`, `"inappropriate"`, `"norms"`, `"other"`, `"spam"`.  (e.g. harassment)
  --description: string # A short description with additional context about why the current user is reporting the target message for moderation.  Clients should limit this string to 1000 Unicode code points.  If the `report_type` parameter is `"other"`, this parameter is required, and its value cannot be an empty string.  (e.g. This message insults and mocks Frodo, which is against the code of conduct.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($message_id)/report")
  let body = {report_type: $report_type, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Upload a file
#
# POST /user_uploads
# operationId: upload-file
export def "user-uploads upload-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filename: string # format: binary, e.g. /path/to/file
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, uri: string, url: string, filename: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_uploads")
  let body = {filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Check thumbnail status
#
# GET /thumbnail/status/{realm_id_str}/{filename}
# operationId: check-thumbnail-status
export def "thumbnail-status check-thumbnail-status" [
  realm_id_str: int
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, has_thumbnail: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/thumbnail/status/($realm_id_str)/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public temporary URL for an uploaded file
#
# GET /user_uploads/{realm_id_str}/{filename}
# operationId: get-file-temporary-url
export def "user-uploads get-file-temporary-url" [
  realm_id_str: int
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_uploads/($realm_id_str)/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users
#
# GET /users
# operationId: get-users
export def "users get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-gravatar: oneof<nothing, bool> # Whether the client supports computing gravatars URLs. If enabled, `avatar_url` will be included in the response only if there is a Zulip avatar, and will be `null` for users who are using gravatar as their avatar. This option significantly reduces the compressed size of user data, since gravatar URLs are long, random strings and thus do not compress well. The `client_gravatar` field is set to `true` if clients can compute their own gravatars.  **Changes**: The default value of this parameter was `false` prior to Zulip 5.0 (feature level 92).  (default: true, e.g. false)
  --include-custom-profile-fields: oneof<nothing, bool> # Whether the client wants [custom profile field](/help/custom-profile-fields) data to be included in the response.  **Changes**: New in Zulip 2.1.0. Previous versions do not offer these data via the API.  (default: false, e.g. true)
  --user-ids: string # Limits the results to the specified user IDs. If not provided, the server will return all accessible users in the organization.  **Changes**: New in Zulip 11.0 (feature level 384).
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, members: table<user_id: any, delivery_email: any, email: any, full_name: any, date_joined: any, is_active: any, is_owner: any, is_admin: any, is_guest: any, is_bot: any, bot_type: any, bot_owner_id: any, role: any, timezone: any, avatar_url: any, avatar_version: any, is_imported_stub: any, is_deleted: any, profile_data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_gravatar" $client_gravatar "scalar") (serialize-qp "include_custom_profile_fields" $include_custom_profile_fields "scalar") (serialize-qp "user_ids" $user_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /users
# operationId: create-user
export def "users create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the new user.  (e.g. username@example.com)
  password: string # The password of the new user.  (e.g. abcd1234)
  full_name: string # The full name of the new user.  (e.g. New User)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {email: $email, password: $password, full_name: $full_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Reactivate a user
#
# POST /users/{user_id}/reactivate
# operationId: reactivate-user
export def "users-reactivate reactivate-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/reactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user status
#
# POST /users/{user_id}/status
# operationId: update-status-for-user
export def "users-status update-status-for-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-text: string # The text content of the status message. Sending the empty string will clear the user's status.  **Note**: The limit on the size of the message is 60 Unicode code points.  (e.g. on vacation)
  --emoji-name: string # The name for the emoji to associate with this status.  **Changes**: New in Zulip 5.0 (feature level 86).  (e.g. car)
  --emoji-code: string # A unique identifier, defining the specific emoji codepoint requested, within the namespace of the `reaction_type`.  **Changes**: New in Zulip 5.0 (feature level 86).  (e.g. 1f697)
  --reaction-type: string # A string indicating the type of emoji. Each emoji `reaction_type` has an independent namespace for values of `emoji_code`.  Must be one of the following values:  - `unicode_emoji` : In this namespace, `emoji_code` will be a   dash-separated hex encoding of the sequence of Unicode codepoints   that define this emoji in the Unicode specification.  - `realm_emoji` : In this namespace, `emoji_code` will be the ID of   the uploaded [custom emoji](/help/custom-emoji).  - `zulip_extra_emoji` : These are special emoji included with Zulip.   In this namespace, `emoji_code` will be the name of the emoji (e.g.   "zulip").  **Changes**: New in Zulip 5.0 (feature level 86).  (e.g. unicode_emoji)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/status")
  let body = {status_text: $status_text, emoji_name: $emoji_name, emoji_code: $emoji_code, reaction_type: $reaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a user's status
#
# GET /users/{user_id}/status
# operationId: get-user-status
export def "users-status get-user-status" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, status: record<away: bool, status_text: string, emoji_name: string, emoji_code: string, reaction_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's presence
#
# GET /users/{user_id_or_email}/presence
# operationId: get-user-presence
export def "users-presence get-user-presence" [
  user_id_or_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, server_timestamp: float, presence: record<active_timestamp: int, idle_timestamp: int, website: record<status: string, timestamp: int>, aggregated: record<status: string, timestamp: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id_or_email)/presence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get own user
#
# GET /users/me
# operationId: get-own-user
export def "users-me get-own-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, avatar_url: string, avatar_version: int, email: string, full_name: string, is_admin: bool, is_owner: bool, role: int, is_guest: bool, is_bot: bool, is_active: bool, timezone: string, date_joined: string, max_message_id: int, user_id: int, delivery_email: string, is_imported_stub: bool, profile_data: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate own user
#
# DELETE /users/me
# operationId: deactivate-own-user
export def "users-me deactivate-own-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerate your API key
#
# POST /users/me/api_key/regenerate
# operationId: regenerate-api-key
export def "users-me-api-key-regenerate regenerate-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/api_key/regenerate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all alert words
#
# GET /users/me/alert_words
# operationId: get-alert-words
export def "users-me-alert-words get-alert-words" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, alert_words: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/alert_words")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add alert words
#
# POST /users/me/alert_words
# operationId: add-alert-words
export def "users-me-alert-words add-alert-words" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alert_words: list # An array of strings to be added to the user's set of configured alert words. Strings already present in the user's set of alert words already are ignored.  Alert words are case insensitive.  (e.g. [foo, bar])
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, alert_words: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/alert_words")
  let body = {alert_words: $alert_words} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove alert words
#
# DELETE /users/me/alert_words
# operationId: remove-alert-words
export def "users-me-alert-words remove-alert-words" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alert_words: list # An array of strings to be removed from the user's set of configured alert words. Strings that are not in the user's set of alert words are ignored.  (e.g. [foo])
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, alert_words: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/alert_words")
  let body = {alert_words: $alert_words} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update your presence
#
# POST /users/me/presence
# operationId: update-presence
@deprecated --flag slim-presence
export def "users-me-presence update-presence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --last-update-id: int # The identifier that specifies what presence data the client already has received, which allows the server to only return more recent user presence data.  This should be set to `-1` during initialization of the client in order to fetch all user presence data, unless the client is obtaining initial user presence metadata from the [`POST /register`](/api/register-queue) endpoint.  In subsequent queries to this endpoint, this value should be set to the most recent value of `presence_last_update_id` returned by the server in this endpoint's response, which implements incremental fetching of user presence data.  When this parameter is passed, the user presence data in the response will always be in the modern format.  **Changes**: New in Zulip 9.0 (feature level 263). Previously, the server sent user presence data for all users who had been active in the last two weeks unconditionally.  (e.g. 5)
  --history-limit-days: int # Limits how far back in time to fetch user presence data. If not specified, defaults to 14 days. A value of N means that the oldest presence data fetched will be from at most N days ago.  Note that this is only useful during the initial user presence data fetch, as subsequent fetches should use the `last_update_id` parameter, which will act as the limit on how much presence data is returned. `history_limit_days` is ignored if `last_update_id` is passed with a value greater than `0`, indicating that the client already has some presence data.  **Changes**: New in Zulip 10.0 (feature level 288).  (e.g. 365)
  --new-user-input: oneof<nothing, bool> # Whether the user has interacted with the client (e.g. moved the mouse, used the keyboard, etc.) since the previous presence request from this client.  The server uses data from this parameter to implement certain [usage statistics](/help/analytics).  User interface clients that might run in the background, without the user ever interacting with them, should be careful to only pass `true` if the user has actually interacted with the client in order to avoid corrupting usage statistics graphs.  (default: false, e.g. false)
  --ping-only: oneof<nothing, bool> # Whether the client is sending a ping-only request, meaning it only wants to update the user's presence `status` on the server.  Otherwise, also requests the server return user presence data for all users in the organization, which is further specified by the [`last_update_id`](#parameter-last_update_id) parameter.  (default: false, e.g. false)
  --slim-presence: oneof<nothing, bool> # Legacy parameter for configuring the format (modern or legacy) in which the server will return user presence data for the organization.  Modern clients should use [`last_update_id`](#parameter-last_update_id), which guarantees that user presence data will be returned in the modern format, and should not pass this parameter as `true` unless interacting with an older server.  Legacy clients that do not yet support `last_update_id` may use the value of `true` to request the modern format for user presence data.  **Note**: The legacy format for user presence data will be removed entirely in a future release.  **Changes**: **Deprecated** in Zulip 9.0 (feature level 263). Using the modern `last_update_id` parameter is the recommended way to request the modern format for user presence data.  New in Zulip 3.0 (no feature level as it was an unstable API at that point).  (DEPRECATED, default: false, e.g. false)
  status: string@status-completer # The status of the user on this client.  Clients should report the user as `"active"` on this device if the client knows that the user is presently using the device (and thus would potentially see a notification immediately), even if the user has not directly interacted with the Zulip client.  Otherwise, it should report the user as `"idle"`.  See the related [`new_user_input`](#parameter-new_user_input) parameter for how a client should report whether the user is actively using the Zulip client.  (e.g. active)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, presence_last_update_id: int, server_timestamp: float, presences: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/presence")
  let body = {last_update_id: $last_update_id, history_limit_days: $history_limit_days, new_user_input: $new_user_input, ping_only: $ping_only, slim_presence: $slim_presence, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update your profile data
#
# PATCH /users/me/profile_data
# operationId: update-profile-data
# --data item shape: {id: int, value: any}
export def "users-me-profile-data update-profile-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # An array of objects describing updates to the custom profile field data for the user.  (e.g. [{id: 4, value: 0}, {id: 5, value: 1909-04-05}]) — item shape: {id: int, value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/profile_data")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove your profile data
#
# DELETE /users/me/profile_data
# operationId: remove-profile-data
export def "users-me-profile-data remove-profile-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # An array of custom profile field IDs to remove any data set for the user.  (e.g. [1])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/profile_data")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update your status
#
# POST /users/me/status
# operationId: update-status
@deprecated --flag away
export def "users-me-status update-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-text: string # The text content of the status message. Sending the empty string will clear the user's status.  **Note**: The limit on the size of the message is 60 Unicode code points.  (e.g. on vacation)
  --away: oneof<nothing, bool> # Whether the user should be marked as "away".  **Changes**: Deprecated in Zulip 6.0 (feature level 148); starting with that feature level, `away` is a legacy way to access the user's `presence_enabled` setting, with `away = !presence_enabled`. To be removed in a future release.  (DEPRECATED, e.g. true)
  --emoji-name: string # The name for the emoji to associate with this status.  **Changes**: New in Zulip 5.0 (feature level 86).  (e.g. car)
  --emoji-code: string # A unique identifier, defining the specific emoji codepoint requested, within the namespace of the `reaction_type`.  **Changes**: New in Zulip 5.0 (feature level 86).  (e.g. 1f697)
  --reaction-type: string # A string indicating the type of emoji. Each emoji `reaction_type` has an independent namespace for values of `emoji_code`.  Must be one of the following values:  - `unicode_emoji` : In this namespace, `emoji_code` will be a   dash-separated hex encoding of the sequence of Unicode codepoints   that define this emoji in the Unicode specification.  - `realm_emoji` : In this namespace, `emoji_code` will be the ID of   the uploaded [custom emoji](/help/custom-emoji).  - `zulip_extra_emoji` : These are special emoji included with Zulip.   In this namespace, `emoji_code` will be the name of the emoji (e.g.   "zulip").  **Changes**: New in Zulip 5.0 (feature level 86).  (e.g. unicode_emoji)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/status")
  let body = {status_text: $status_text, away: $away, emoji_name: $emoji_name, emoji_code: $emoji_code, reaction_type: $reaction_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get topics in a channel
#
# GET /users/me/{stream_id}/topics
# operationId: get-stream-topics
export def "users-me-topics get-stream-topics" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-empty-topic-name: oneof<nothing, bool> # Whether the client supports processing the empty string as a topic name in the returned data.  If `false`, the value of `realm_empty_topic_display_name` found in the [`POST /register`](/api/register-queue) response is returned replacing the empty string as the topic name.  **Changes**: New in Zulip 10.0 (feature level 334). Previously, the empty string was not a valid topic.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, topics: table<max_id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allow_empty_topic_name" $allow_empty_topic_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/me/($stream_id)/topics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subscribed channels
#
# GET /users/me/subscriptions
# operationId: get-subscriptions
export def "users-me-subscriptions get-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-subscribers: string@include-subscribers-completer # Whether each returned channel object should include a `subscribers` field containing a list of the user IDs of its subscribers.  Client apps supporting organizations with many thousands of users should not pass `true`, because the full subscriber matrix may be several megabytes of data. The `partial` value, combined with the `subscriber_count` and fetching subscribers for individual channels as needed, is recommended to support client app features where channel subscriber data is useful.  If a client passes `partial` for this parameter, the server may, for some channels, return a subset of the channel's subscribers in the `partial_subscribers` field instead of the `subscribers` field, which always contains the complete set of subscribers.  The server guarantees that it will always return a `subscribers` field for channels with fewer than 250 total subscribers. When returning a `partial_subscribers` field, the server guarantees that all bot users and users active within the last 14 days will be included. For other cases, the server may use its discretion to determine which channels and users to include, balancing between payload size and usefulness of the data provided to the client.  **Changes**: The `partial` value is new in Zulip 11.0 (feature level 412).  New in Zulip 2.1.0.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, subscriptions: table<stream_id: int, name: string, description: string, rendered_description: string, date_created: int, creator_id: int, invite_only: bool, subscribers: list, partial_subscribers: list, desktop_notifications: bool, email_notifications: bool, wildcard_mentions_notify: bool, push_notifications: bool, audible_notifications: bool, pin_to_top: bool, is_muted: bool, in_home_view: bool, is_announcement_only: bool, is_web_public: bool, color: string, stream_post_policy: int, message_retention_days: int, history_public_to_subscribers: bool, first_message_id: int, folder_id: int, topics_policy: string, is_recently_active: bool, stream_weekly_traffic: int, can_add_subscribers_group: record, can_remove_subscribers_group: record, can_administer_channel_group: record, can_delete_any_message_group: record, can_delete_own_message_group: record, can_move_messages_out_of_channel_group: record, can_move_messages_within_channel_group: record, can_send_message_group: record, can_subscribe_group: record, can_resolve_topics_group: record, can_create_topic_group: record, is_archived: bool, subscriber_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_subscribers" $include_subscribers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe to a channel
#
# POST /users/me/subscriptions
# operationId: subscribe
# --subscriptions item shape: {name: string, description?: string}
export def "users-me-subscriptions subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscriptions: list # A list of dictionaries containing the key `name` and value specifying the name of the channel to subscribe. If the channel does not exist a new channel is created. The description of the channel created can be specified by setting the dictionary key `description` with an appropriate value.  (e.g. [{name: Verona, description: Italian city}]) — item shape: {name: string, description?: string}
  --principals: any # A list of user IDs (preferred) or Zulip API email addresses of the users to be subscribed to or unsubscribed from the channels specified in the `subscriptions` parameter.  If not provided, then the requesting user/bot will be subscribed/unsubscribed from the specified channels.  **Changes**: Before Zulip 3.0 (feature level 9), only the Zulip API email address string format was supported.  (e.g. [11])
  --authorization-errors-fatal: oneof<nothing, bool> # A boolean specifying whether authorization errors (such as when the requesting user is not authorized to access a private channel) should be considered fatal or not. When `true`, an authorization error is reported as such. When set to `false`, the response will be a 200 and any channels where the request encountered an authorization error will be listed in the `unauthorized` key.  (default: true, e.g. false)
  --announce: oneof<nothing, bool> # If one of the channels specified did not exist previously and is thus created by this call, this determines whether [notification bot](/help/configure-automated-notices) will send an announcement about the new channel's creation.  (default: false, e.g. true)
  --invite-only: oneof<nothing, bool> # As described above, this endpoint will create a new channel if passed a channel name that doesn't already exist. This parameters and the ones that follow are used to request an initial configuration of a created channel; they are ignored for channels that already exist.  This parameter determines whether any newly created channels will be private channels.  (default: false, e.g. true)
  --is-web-public: oneof<nothing, bool> # This parameter determines whether any newly created channels will be web-public channels.  Note that creating web-public channels requires the `WEB_PUBLIC_STREAMS_ENABLED` [server setting][server-settings] to be enabled on the Zulip server in question, the organization to have enabled the `enable_spectator_access` realm setting, and the current use to have permission under the organization's `can_create_web_public_channel_group` realm setting.  [server-settings]: https://zulip.readthedocs.io/en/stable/production/settings.html  **Changes**: New in Zulip 5.0 (feature level 98).  (default: false, e.g. true)
  --is-default-stream: oneof<nothing, bool> # This parameter determines whether any newly created channels will be added as [default channels][default-channels] for new users joining the organization.  [default-channels]: /help/set-default-channels-for-new-users  **Changes**: New in Zulip 8.0 (feature level 200). Previously, default channel status could only be changed using the [dedicated API endpoint](/api/add-default-stream).  (default: false, e.g. true)
  --history-public-to-subscribers: oneof<nothing, bool> # Whether the channel's message history should be available to newly subscribed members, or users can only access messages they actually received while subscribed to the channel.  Corresponds to the shared history option for [private channels](/help/channel-permissions#private-channels).  (e.g. false)
  --message-retention-days: any # Number of days that messages sent to this channel will be stored before being automatically deleted by the [message retention policy](/help/message-retention-policy). Two special string format values are supported:  - `"realm_default"`: Return to the organization-level setting. - `"unlimited"`: Retain messages forever.  **Changes**: Prior to Zulip 5.0 (feature level 91), retaining messages forever was encoded using `"forever"` instead of `"unlimited"`.  New in Zulip 3.0 (feature level 17).  (e.g. 20)
  --topics-policy: string@topics-policy-completer # Whether [named topics](/help/introduction-to-topics) and the empty topic (i.e., ["general chat" topic](/help/general-chat-topic)) are enabled in this channel.  - `"inherit"`: Messages can be sent to named topics in this channel,   and the [organization-level `realm_topics_policy`][realm-topics-policy]   is used for whether messages can be sent to the empty topic in this   channel. - `"allow_empty_topic"`: Messages can be sent to both named topics and   the empty topic in this channel. - `"disable_empty_topic"`: Messages can be sent to named topics in this   channel, but the empty topic is disabled. - `"empty_topic_only"`: Messages can be sent to the empty topic in this   channel, but named topics are disabled. See ["general chat"   channels](/help/general-chat-channels).  The `"empty_topic_only"` policy can only be set if all existing messages in the channel are already in the empty topic.  When creating a new channel, if the `topics_policy` is not specified, the `"inherit"` option will be set.  **Changes**: In Zulip 11.0 (feature level 404), the `"empty_topic_only"` option was added.  New in Zulip 11.0 (feature level 392).  [realm-topics-policy]: /help/require-topics#set-the-default-general-chat-topic-configuration  (e.g. inherit)
  --can-add-subscribers-group: any
  --can-remove-subscribers-group: any
  --can-administer-channel-group: any
  --can-delete-any-message-group: any
  --can-delete-own-message-group: any
  --can-move-messages-out-of-channel-group: any
  --can-move-messages-within-channel-group: any
  --can-send-message-group: any
  --can-subscribe-group: any
  --can-resolve-topics-group: any
  --can-create-topic-group: any
  --folder-id: int # This parameter adds the newly created channel to the specified [channel folder](/help/channel-folders).  **Changes**: New in Zulip 11.0 (feature level 389).  (e.g. 1)
  --send-new-subscription-messages: oneof<nothing, bool> # Whether any other users newly subscribed via this request should be sent a direct message, from Notification Bot, notifying them about their new subscription.  No direct messages are sent for any channels that are created as part of this request, regardless of the value of this parameter.  The server will never send direct messages when the total number of users who were subscribed to channels in this request was more than the value of `max_bulk_new_subscription_messages`, which is available in the [`POST /register`](/api/register-queue) response.  **Changes**: Before Zulip 11.0 (feature level 397), new subscribers were always sent a Notification Bot direct message, which was unduly expensive when bulk-subscribing thousands of users to a channel.  (default: true, e.g. true)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, subscribed: record, already_subscribed: record, unauthorized: list<string>, new_subscription_messages_sent: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/subscriptions")
  let body = {subscriptions: $subscriptions, principals: $principals, authorization_errors_fatal: $authorization_errors_fatal, announce: $announce, invite_only: $invite_only, is_web_public: $is_web_public, is_default_stream: $is_default_stream, history_public_to_subscribers: $history_public_to_subscribers, message_retention_days: $message_retention_days, topics_policy: $topics_policy, can_add_subscribers_group: $can_add_subscribers_group, can_remove_subscribers_group: $can_remove_subscribers_group, can_administer_channel_group: $can_administer_channel_group, can_delete_any_message_group: $can_delete_any_message_group, can_delete_own_message_group: $can_delete_own_message_group, can_move_messages_out_of_channel_group: $can_move_messages_out_of_channel_group, can_move_messages_within_channel_group: $can_move_messages_within_channel_group, can_send_message_group: $can_send_message_group, can_subscribe_group: $can_subscribe_group, can_resolve_topics_group: $can_resolve_topics_group, can_create_topic_group: $can_create_topic_group, folder_id: $folder_id, send_new_subscription_messages: $send_new_subscription_messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update subscriptions
#
# PATCH /users/me/subscriptions
# operationId: update-subscriptions
# --add item shape: {name?: string, color?: string, description?: string}
export def "users-me-subscriptions update-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: list # A list of channel names to unsubscribe from.  (e.g. [Verona, Denmark])
  --add: list # A list of objects describing which channels to subscribe to, optionally including per-user subscription parameters (e.g. color) and if the channel is to be created, its description.  (e.g. [{name: Verona}, {name: Denmark, color: #e79ab5, description: A Scandinavian country}]) — item shape: {name?: string, color?: string, description?: string}
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, subscribed: record, already_subscribed: record, not_removed: list<string>, removed: list<string>, new_subscription_messages_sent: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/subscriptions")
  let body = {delete: $delete, add: $add} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unsubscribe from a channel
#
# DELETE /users/me/subscriptions
# operationId: unsubscribe
export def "users-me-subscriptions unsubscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscriptions: list # A list of channel names to unsubscribe from. This parameter is called `streams` in our Python API.  (e.g. [Verona, Denmark])
  --principals: any # A list of user IDs (preferred) or Zulip API email addresses of the users to be subscribed to or unsubscribed from the channels specified in the `subscriptions` parameter.  If not provided, then the requesting user/bot will be subscribed/unsubscribed from the specified channels.  **Changes**: Before Zulip 3.0 (feature level 9), only the Zulip API email address string format was supported.  (e.g. [11])
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, not_removed: list<string>, removed: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/subscriptions")
  let body = {subscriptions: $subscriptions, principals: $principals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Topic muting
#
# PATCH /users/me/subscriptions/muted_topics
# DEPRECATED
# operationId: mute-topic
@deprecated
export def "users-me-subscriptions-muted-topics mute-topic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream-id: int # The ID of the channel to access.  Clients must provide either `stream` or `stream_id` as a parameter to this endpoint, but not both.  **Changes**: New in Zulip 2.0.0.  (e.g. 43)
  --stream: string # The name of the channel to access.  Clients must provide either `stream` or `stream_id` as a parameter to this endpoint, but not both. Clients should use `stream_id` instead of the `stream` parameter when possible.  (e.g. Denmark)
  topic: string # The topic to (un)mute. Note that the request will succeed regardless of whether any messages have been sent to the specified topic.  Clients should use the `max_topic_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum topic length.  (e.g. dinner)
  op: string@op-completer # Whether to mute (`add`) or unmute (`remove`) the provided topic.  (e.g. add)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/subscriptions/muted_topics")
  let body = {stream_id: $stream_id, stream: $stream, topic: $topic, op: $op} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Send a test notification to mobile device(s)
#
# POST /mobile_push/test_notification
# DEPRECATED
# operationId: test-notify
@deprecated
export def "mobile-push-test-notification test-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The push token for the device to which to send the test notification.  If this parameter is not submitted, the test notification will be sent to all of the user's devices registered on the server.  A mobile client should pass this parameter, to avoid triggering a test notification for other clients.  (e.g. 111222)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mobile_push/test_notification")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Send an E2EE test notification to mobile device(s)
#
# POST /mobile_push/e2ee/test_notification
# operationId: e2ee-test-notify
export def "mobile-push-e2ee-test-notification e2ee-test-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --device-id: int # The ID for the device to which to send the test notification.  If this parameter is not submitted, the E2EE test notification will be sent to all of the user's devices registered on the server.  A mobile client should pass this parameter, to avoid triggering a test notification for other clients.  See [`POST /register_client_device`](/api/register-client-device) for details on device ID.  **Changes**: New in Zulip 12.0 (feature level 468).  Previously, `push_account_id` was used.  (e.g. 1144)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mobile_push/e2ee/test_notification")
  let body = {device_id: $device_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Register E2EE push device
#
# POST /mobile_push/register
# operationId: register-push-device
export def "mobile-push-register register-push-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  device_id: int # The ID of the device to configure for push notifications.  See [`POST /register_client_device`](/api/register-client-device) for how to obtain a device ID.  (e.g. 1)
  --push-key-id: int # A random unsigned 32-bit integer generated by the client as an identifier for `push_key`. It will be included in mobile push notifications along with encrypted payloads to identify the `push_key` to decrypt.  (e.g. 2408)
  --push-key: string # Key that the client would like the server to use to encrypt notifications, encoded with Base64.  The key is a byte sequence beginning with a single byte that encodes which cryptosystem to use, followed by the key to use for that cryptosystem. This byte sequence is encoded using standard Base64 encoding as defined in RFC 4648.  The client should avoid sharing the key anywhere else: in particular it should generate a fresh key for each server, and to the extent possible keep the key out of any backups of the client's data.  Supported cryptosystems are:  - `0x31`: LibSodium's [SecretBox][libsodium-secretbox] symmetric key encryption   system. Keys are 32 bytes, which the server will use with libsodium's   `crypto_secretbox_easy`. See the [NaCl documentation][nacl-secretbox], which   details how this system uses `XSalsa20` and `Poly1305` to provide authenticated   encryption.  [libsodium-secretbox]: https://libsodium.gitbook.io/doc/secret-key_cryptography/secretbox [nacl-secretbox]: https://nacl.cr.yp.to/secretbox.html  **Changes**: New in Zulip 12.0 (feature level 432). This replaced the `push_public_key` parameter which had a prototype asymmetric cryptosystem, and did not have a natural way to support multiple cryptosystems.  (e.g. MTaUDJDMWypQ1WufZ1NRTHSSvgYtXh1qVNSjN3aBiEFt)
  --token-kind: string@token-kind-completer # Whether the token was generated by FCM or APNs.  (e.g. fcm)
  --token-id: string # Identifier for the FCM/APNs provided token to the device, produced by taking the first 8 bytes of the SHA-256 hash of the token, then encoding those bytes using standard Base64 encoding as defined in RFC 4648.  (e.g. hGsEWGmyyfI=)
  --bouncer-public-key: string # Which of the bouncer's public keys the client used to encrypt the `PushRegistration` dictionary.  When the bouncer rotates the key, a new asymmetric key pair is created, and the new public key is baked into a new client release. Because the bouncer routinely rotates key, this field clarifies which public key the client is using.  The public key is encoded using standard Base64 encoding as defined in RFC 4648.  (e.g. bouncer-public-key)
  --encrypted-push-registration: string # Ciphertext generated by encrypting a `PushRegistration` dictionary using the `bouncer_public_key`, encoded using a RFC 4648 standard base64 encoder.  The `PushRegistration` dictionary contains the fields `token`, `token_kind`, `timestamp`, and (for iOS devices) `ios_app_id`. The dictionary is JSON-encoded before encryption.  (e.g. encrypted-push-registration-data)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mobile_push/register")
  let body = {device_id: $device_id, push_key_id: $push_key_id, push_key: $push_key, token_kind: $token_kind, token_id: $token_id, bouncer_public_key: $bouncer_public_key, encrypted_push_registration: $encrypted_push_registration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Register E2EE push device to bouncer
#
# POST /remotes/push/e2ee/register
# operationId: register-remote-push-device
export def "remotes-push-e2ee-register register-remote-push-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  realm_uuid: string # The UUID of the realm to which the push device being registered belongs.  (e.g. 9aa61d0b-8ce5-488d-8e9e-fedc346e6836)
  token_id: string # The `token_id` value provided by the mobile client to [register E2EE push device](/api/register-push-device).  **Changes**: New in Zulip 12.0 (feature level 468), replacing `push_account_id`.  (e.g. +wKIhyAx/Eg=)
  encrypted_push_registration: string # The `encrypted_push_registration` value provided by the mobile client to [register E2EE push device](/api/register-push-device).  (e.g. encrypted-push-registration-data)
  bouncer_public_key: string # The `bouncer_public_key` value provided by the mobile client to [register E2EE push device](/api/register-push-device).  (e.g. bouncer-public-key)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/remotes/push/e2ee/register")
  let body = {realm_uuid: $realm_uuid, token_id: $token_id, encrypted_push_registration: $encrypted_push_registration, bouncer_public_key: $bouncer_public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Register a logged-in device
#
# POST /register_client_device
# operationId: register-client-device
export def "register-client-device register-client-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, device_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/register_client_device")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a registered device
#
# POST /remove_client_device
# operationId: remove-client-device
export def "remove-client-device remove-client-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  device_id: int # The ID of the device to remove.  (e.g. 2)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/remove_client_device")
  let body = {device_id: $device_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update personal preferences for a topic
#
# POST /user_topics
# operationId: update-user-topic
export def "user-topics update-user-topic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stream_id: int # The ID of the channel to access.  (e.g. 1)
  topic: string # The topic for which the personal preferences needs to be updated. Note that the request will succeed regardless of whether any messages have been sent to the specified topic.  Clients should use the `max_topic_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum topic length.  Note: When the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  **Changes**: Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  (e.g. dinner)
  visibility_policy: int@visibility-policy-completer # Controls which visibility policy to set.  - 0 = None. Removes the visibility policy previously set for the topic. - 1 = Muted. [Mutes the topic](/help/mute-a-topic) in a channel. - 2 = Unmuted. [Unmutes the topic](/help/mute-a-topic) in a muted channel. - 3 = Followed. [Follows the topic](/help/follow-a-topic).  In an unmuted channel, a topic visibility policy of unmuted will have the same effect as the "None" visibility policy.  **Changes**: In Zulip 7.0 (feature level 219), added followed as a visibility policy option.  (e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_topics")
  let body = {stream_id: $stream_id, topic: $topic, visibility_policy: $visibility_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Mute a user
#
# POST /users/me/muted_users/{muted_user_id}
# operationId: mute-user
export def "users-me-muted-users mute-user" [
  muted_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/muted_users/($muted_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unmute a user
#
# DELETE /users/me/muted_users/{muted_user_id}
# operationId: unmute-user
export def "users-me-muted-users unmute-user" [
  muted_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/muted_users/($muted_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an APNs device token
#
# POST /users/me/apns_device_token
# DEPRECATED
# operationId: add-apns-token
@deprecated
export def "users-me-apns-device-token add-apns-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The token provided by the device.  (e.g. c0ffee)
  appid: string # The ID of the Zulip app that is making the request.  **Changes**: In Zulip 8.0 (feature level 223), this parameter was made required. Previously, if it was unspecified, the server would use a default value (based on the `ZULIP_IOS_APP_ID` server setting, which defaulted to `"org.zulip.Zulip"`).  (e.g. org.zulip.Zulip)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/apns_device_token")
  let body = {token: $body_token, appid: $appid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an APNs device token
#
# DELETE /users/me/apns_device_token
# DEPRECATED
# operationId: remove-apns-token
@deprecated
export def "users-me-apns-device-token remove-apns-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The token provided by the device.  (e.g. c0ffee)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/apns_device_token")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add an FCM registration token
#
# POST /users/me/android_gcm_reg_id
# DEPRECATED
# operationId: add-fcm-token
@deprecated
export def "users-me-android-gcm-reg-id add-fcm-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The token provided by the device.  (e.g. android-token)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/android_gcm_reg_id")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an FCM registration token
#
# DELETE /users/me/android_gcm_reg_id
# DEPRECATED
# operationId: remove-fcm-token
@deprecated
export def "users-me-android-gcm-reg-id remove-fcm-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The token provided by the device.  (e.g. android-token)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/android_gcm_reg_id")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get subscription status
#
# GET /users/{user_id}/subscriptions/{stream_id}
# operationId: get-subscription-status
export def "users-subscriptions get-subscription-status" [
  user_id: int
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, is_subscribed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/subscriptions/($stream_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's subscribed channels
#
# GET /users/{user_id}/channels
# operationId: get-user-channels
export def "users-channels get-user-channels" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, subscribed_channel_ids: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload custom emoji
#
# POST /realm/emoji/{emoji_name}
# operationId: upload-custom-emoji
export def "realm-emoji upload-custom-emoji" [
  emoji_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filename: string # format: binary, e.g. /path/to/img.png
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realm/emoji/($emoji_name)")
  let body = {filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Deactivate custom emoji
#
# DELETE /realm/emoji/{emoji_name}
# operationId: deactivate-custom-emoji
export def "realm-emoji deactivate-custom-emoji" [
  emoji_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realm/emoji/($emoji_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all custom emoji
#
# GET /realm/emoji
# operationId: get-custom-emoji
export def "realm-emoji get-custom-emoji" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, emoji: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/emoji")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get presence of all users
#
# GET /realm/presence
# operationId: get-presence
export def "realm-presence get-presence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, server_timestamp: float, presences: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/presence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get allowed domains
#
# GET /realm/domains
# operationId: get-realm-domains
export def "realm-domains get-realm-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, domains: table<domain: string, allow_subdomains: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an allowed domain
#
# POST /realm/domains
# operationId: add-realm-domain
export def "realm-domains add-realm-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string # The new domain.  **Changes**: In Zulip 4.0 (feature level 63), the unnecessary JSON-encoding of this parameter was removed.  (e.g. example.com)
  --allow-subdomains: oneof<nothing, bool> # Whether subdomains are allowed for this domain.  (e.g. false)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, new_domain: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/domains")
  let body = {domain: $domain, allow_subdomains: $allow_subdomains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update an allowed domain
#
# PATCH /realm/domains/{domain}
# operationId: patch-realm-domain
export def "realm-domains patch-realm-domain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-subdomains: oneof<nothing, bool> # Whether subdomains are allowed for this domain.  (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realm/domains/($domain)")
  let body = {allow_subdomains: $allow_subdomains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an allowed domain
#
# DELETE /realm/domains/{domain}
# operationId: delete-realm-domain
export def "realm-domains delete-realm-domain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realm/domains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all custom profile fields
#
# GET /realm/profile_fields
# operationId: get-custom-profile-fields
export def "realm-profile-fields get-custom-profile-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, custom_fields: table<id: int, type: int, order: int, name: string, hint: string, field_data: string, display_in_profile_summary: bool, required: bool, editable_by_user: bool, use_for_user_matching: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/profile_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder custom profile fields
#
# PATCH /realm/profile_fields
# operationId: reorder-custom-profile-fields
export def "realm-profile-fields reorder-custom-profile-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  order: list # A list of the IDs of all the custom profile fields defined in this organization, in the desired new order.  (e.g. [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/profile_fields")
  let body = {order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a custom profile field
#
# POST /realm/profile_fields
# operationId: create-custom-profile-field
export def "realm-profile-fields create-custom-profile-field" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the custom profile field, which will appear both in user-facing settings UI for configuring custom profile fields and in UI displaying a user's profile.  (e.g. Favorite programming language)
  --hint: string # The help text to be displayed for the custom profile field in user-facing settings UI for configuring custom profile fields.  (e.g. Your favorite programming language.)
  field_type: int # The field type can be any of the supported custom profile field types. See the [custom profile fields documentation](/help/custom-profile-fields) for more details on what each type means.  - **1**: Short text - **2**: Paragraph - **3**: Dropdown - **4**: Date - **5**: Link - **6**: Users - **7**: External account - **8**: Pronouns  **Changes**: Field type `8` added in Zulip 6.0 (feature level 151).  (e.g. 3)
  --field-data: record # Field types 3 (Dropdown) and 7 (External account) support storing additional configuration for the field type in the `field_data` attribute.  For field type 3 (Dropdown), this attribute is a JSON dictionary defining the choices and the order they will be displayed in the dropdown UI for individual users to select an option.  The interface for field type 7 is not yet stabilized.  (e.g. {python: {text: Python, order: 1}, java: {text: Java, order: 2}})
  --display-in-profile-summary: oneof<nothing, bool> # Whether clients should display this profile field in a summary section of a user's profile (or in a more easily accessible "small profile").  At most 2 profile fields may have this property be true in a given organization.  The "Users" profile field is not supported, but that is likely to be temporary.  [profile-field-types]: /help/custom-profile-fields#profile-field-types  **Changes**: Before Zulip 12.0 (feature level 476), the "Paragraph" field type was not supported.  New in Zulip 6.0 (feature level 146).  (e.g. true)
  --required: oneof<nothing, bool> # Whether an organization administrator has configured this profile field as required.  Because the required property is mutable, clients cannot assume that a required custom profile field has a value. The Zulip web application displays a prominent banner to any user who has not set a value for a required field.  **Changes**: New in Zulip 9.0 (feature level 244).  (e.g. true)
  --editable-by-user: oneof<nothing, bool> # Whether regular users can edit this profile field on their own account.  Note that organization administrators can edit custom profile fields for any user regardless of this setting.  **Changes**: New in Zulip 10.0 (feature level 296).  (e.g. true)
  --use-for-user-matching: oneof<nothing, bool> # Whether this custom profile field should be used to match users in typeahead suggestions. Only allowed for Short Text and External Account [profile field types](/help/custom-profile-fields#profile-field-types).  This field is only included when its value is `true`.  **Changes**: New in Zulip 12.0 (feature level 455).  (e.g. false)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/profile_fields")
  let body = {name: $name, hint: $hint, field_type: $field_type, field_data: $field_data, display_in_profile_summary: $display_in_profile_summary, required: $required, editable_by_user: $editable_by_user, use_for_user_matching: $use_for_user_matching} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update realm-level defaults of user settings
#
# PATCH /realm/user_settings_defaults
# operationId: update-realm-user-settings-defaults
export def "realm-user-settings-defaults update-realm-user-settings-defaults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --starred-message-counts: oneof<nothing, bool> # Whether clients should display the [number of starred messages](/help/star-a-message#display-the-number-of-starred-messages).  (e.g. true)
  --receives-typing-notifications: oneof<nothing, bool> # Whether the user is configured to receive typing notifications from other users. The server will only deliver typing notifications events to users who for whom this is enabled.  **Changes**: New in Zulip 9.0 (feature level 253). Previously, there were only options to disable sending typing notifications.  (e.g. true)
  --web-suggest-update-timezone: oneof<nothing, bool> # Whether the user should be shown an alert, offering to update their [profile time zone](/help/change-your-timezone), when the time displayed for the profile time zone differs from the current time displayed by the time zone configured on their device.  **Changes**: New in Zulip 10.0 (feature level 329).  (e.g. true)
  --fluid-layout-width: oneof<nothing, bool> # Whether to use the [maximum available screen width](/help/enable-full-width-display) for the web app's center panel (message feed, recent conversations) on wide screens.  (e.g. true)
  --high-contrast-mode: oneof<nothing, bool> # This setting is reserved for use to control variations in Zulip's design to help visually impaired users.  (e.g. true)
  --web-mark-read-on-scroll-policy: int@web-mark-read-on-scroll-policy-completer # Whether or not to mark messages as read when the user scrolls through their feed.  - 1 - Always - 2 - Only in conversation views - 3 - Never  **Changes**: New in Zulip 7.0 (feature level 175). Previously, there was no way for the user to configure this behavior on the web, and the Zulip web and desktop apps behaved like the "Always" setting when marking messages as read.  (e.g. 1)
  --web-channel-default-view: int@web-channel-default-view-completer # Web/desktop app setting controlling the default navigation behavior when clicking on a channel link.  - 1 - Top topic in the channel - 2 - Channel feed - 3 - List of topics - 4 - Top unread topic in channel  **Changes**: The "Top unread topic in channel" is new in Zulip 11.0 (feature level 401).  The "List of topics" option is new in Zulip 11.0 (feature level 383).  New in Zulip 9.0 (feature level 269). Previously, this was not configurable, and every user had the "Channel feed" behavior.  (e.g. 1)
  --web-font-size-px: int # User-configured primary `font-size` for the web application, in pixels.  **Changes**: New in Zulip 9.0 (feature level 245). Previously, font size was only adjustable via browser zoom. Note that this setting was not fully implemented at this feature level.  (e.g. 14)
  --web-line-height-percent: int # User-configured primary `line-height` for the web application, in percent, so a value of 120 represents a `line-height` of 1.2.  **Changes**: New in Zulip 9.0 (feature level 245). Previously, line height was not user-configurable. Note that this setting was not fully implemented at this feature level.  (e.g. 122)
  --color-scheme: int@color-scheme-completer # Controls which [color theme](/help/dark-theme) to use.  - 1 - Automatic - 2 - Dark theme - 3 - Light theme  Automatic detection is implementing using the standard `prefers-color-scheme` media query.  (e.g. 1)
  --enable-drafts-synchronization: oneof<nothing, bool> # A boolean parameter to control whether synchronizing drafts is enabled for the user. When synchronization is disabled, all drafts stored in the server will be automatically deleted from the server.  This does not do anything (like sending events) to delete local copies of drafts stored in clients.  (e.g. true)
  --translate-emoticons: oneof<nothing, bool> # Whether to [translate emoticons to emoji](/help/configure-emoticon-translations) in messages the user sends.  (e.g. true)
  --display-emoji-reaction-users: oneof<nothing, bool> # Whether to display the names of reacting users on a message.  When enabled, clients should display the names of reacting users, rather than a count, for messages with few total reactions. The ideal cutoff may depend on the space available for displaying reactions; the official web application displays names when 3 or fewer total reactions are present with this setting enabled.  **Changes**: New in Zulip 6.0 (feature level 125).  (e.g. false)
  --web-home-view: string # The [home view](/help/configure-home-view) used when opening a new Zulip web app window or hitting the `Esc` keyboard shortcut repeatedly.  - "recent" - Recent conversations view - "inbox" - Inbox view - "all_messages" - Combined feed view  **Changes**: Before Zulip 12.0 (feature level 454), the Recent view had `"recent_topics"` as its string encoding.  New in Zulip 8.0 (feature level 219). Previously, this was called `default_view`, which was new in Zulip 4.0 (feature level 42).  (e.g. all_messages)
  --web-escape-navigates-to-home-view: oneof<nothing, bool> # Whether the escape key navigates to the [configured home view](/help/configure-home-view).  **Changes**: New in Zulip 8.0 (feature level 219). Previously, this was called `escape_navigates_to_default_view`, which was new in Zulip 5.0 (feature level 107).  (e.g. true)
  --left-side-userlist: oneof<nothing, bool> # Whether the users list on left sidebar in narrow windows.  This feature is not heavily used and is likely to be reworked.  (e.g. true)
  --emojiset: string # The user's configured [emoji set](/help/emoji-and-emoticons#use-emoticons), used to display emoji to the user everywhere they appear in the UI.  - "google" - Google - "twitter" - Twitter - "text" - Plain text  (e.g. google)
  --demote-inactive-streams: int@demote-inactive-streams-completer # Whether to [hide inactive channels](/help/manage-inactive-channels) in the left sidebar.  - 1 - Automatic - 2 - Always - 3 - Never  (e.g. 1)
  --user-list-style: int@user-list-style-completer # The style selected by the user for the right sidebar user list.  - 1 - Compact - 2 - With status - 3 - With avatar and status  **Changes**: New in Zulip 6.0 (feature level 141).  (e.g. 1)
  --web-animate-image-previews: string@web-animate-image-previews-completer # Controls how animated images should be played in the message feed in the web/desktop application.  - "always" - Always play the animated images in the message feed. - "on_hover" - Play the animated images on hover over them in the message feed. - "never" - Never play animated images in the message feed.  **Changes**: New in Zulip 9.0 (feature level 275). Previously, animated images always used to play in the message feed by default. This setting controls this behaviour.  (e.g. on_hover)
  --web-stream-unreads-count-display-policy: int@web-stream-unreads-count-display-policy-completer # Configuration for which channels should be displayed with a numeric unread count in the left sidebar. Channels that do not have an unread count will have a simple dot indicator for whether there are any unread messages.  - 1 - All channels - 2 - Unmuted channels and topics - 3 - No channels  **Changes**: New in Zulip 8.0 (feature level 210).  (e.g. 2)
  --hide-ai-features: oneof<nothing, bool> # Controls whether user wants AI features like topic summarization to be hidden in all Zulip clients.  **Changes**: New in Zulip 10.0 (feature level 350).
  --web-inbox-show-channel-folders: oneof<nothing, bool> # Determines whether [channel folders](/help/channel-folders) are used to organize how conversations with unread messages are displayed in the web/desktop application's Inbox view.  **Changes**: New in Zulip 12.0 (feature level 431).  (e.g. true)
  --web-left-sidebar-show-channel-folders: oneof<nothing, bool> # Determines whether [channel folders](/help/channel-folders) are used to organize how channels are displayed in the web/desktop application's left sidebar.  **Changes**: New in Zulip 11.0 (feature level 411).  (e.g. true)
  --web-left-sidebar-unreads-count-summary: oneof<nothing, bool> # Determines whether the web/desktop application's left sidebar displays the unread message count summary.  **Changes**: New in Zulip 11.0 (feature level 398).  (e.g. true)
  --enable-stream-desktop-notifications: oneof<nothing, bool> # Enable visual desktop notifications for channel messages.  (e.g. true)
  --enable-stream-email-notifications: oneof<nothing, bool> # Enable email notifications for channel messages.  (e.g. true)
  --enable-stream-push-notifications: oneof<nothing, bool> # Enable mobile notifications for channel messages.  (e.g. true)
  --enable-stream-audible-notifications: oneof<nothing, bool> # Enable audible desktop notifications for channel messages.  (e.g. true)
  --notification-sound: string # Notification sound name.  (e.g. ding)
  --enable-desktop-notifications: oneof<nothing, bool> # Enable visual desktop notifications for direct messages and @-mentions.  (e.g. true)
  --enable-sounds: oneof<nothing, bool> # Enable audible desktop notifications for direct messages and @-mentions.  (e.g. true)
  --enable-followed-topic-desktop-notifications: oneof<nothing, bool> # Enable visual desktop notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. true)
  --enable-followed-topic-email-notifications: oneof<nothing, bool> # Enable email notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. true)
  --enable-followed-topic-push-notifications: oneof<nothing, bool> # Enable push notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. false)
  --enable-followed-topic-audible-notifications: oneof<nothing, bool> # Enable audible desktop notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. false)
  --email-notifications-batching-period-seconds: int # The duration (in seconds) for which the server should wait to batch email notifications before sending them.  (e.g. 120)
  --enable-offline-email-notifications: oneof<nothing, bool> # Enable email notifications for direct messages and @-mentions received when the user is offline.  (e.g. true)
  --enable-offline-push-notifications: oneof<nothing, bool> # Enable mobile notification for direct messages and @-mentions received when the user is offline.  (e.g. true)
  --enable-online-push-notifications: oneof<nothing, bool> # Enable mobile notification for direct messages and @-mentions received when the user is online.  (e.g. true)
  --enable-digest-emails: oneof<nothing, bool> # Enable digest emails when the user is away.  (e.g. true)
  --message-content-in-email-notifications: oneof<nothing, bool> # Include the message's content in email notifications for new messages.  (e.g. true)
  --pm-content-in-desktop-notifications: oneof<nothing, bool> # Include content of direct messages in desktop notifications.  (e.g. true)
  --wildcard-mentions-notify: oneof<nothing, bool> # Whether wildcard mentions (E.g. @**all**) should send notifications like a personal mention.  (e.g. true)
  --enable-followed-topic-wildcard-mentions-notify: oneof<nothing, bool> # Whether wildcard mentions (e.g., @**all**) in messages sent to followed topics should send notifications like a personal mention.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. true)
  --desktop-icon-count-display: int@desktop-icon-count-display-completer # Unread count badge (appears in desktop sidebar and browser tab)  - 1 - All unread messages - 2 - DMs, mentions, and followed topics - 3 - DMs and mentions - 4 - None  **Changes**: In Zulip 8.0 (feature level 227), added `DMs, mentions, and followed topics` option, renumbering the options to insert it in order.  (e.g. 1)
  --realm-name-in-email-notifications-policy: int@realm-name-in-email-notifications-policy-completer # Whether to [include organization name in subject of message notification emails](/help/email-notifications#include-organization-name-in-subject-line).  - 1 - Automatic - 2 - Always - 3 - Never  **Changes**: New in Zulip 7.0 (feature level 168), replacing the previous `realm_name_in_notifications` boolean; `true` corresponded to `Always`, and `false` to `Never`.  (e.g. 1)
  --automatically-follow-topics-policy: int@automatically-follow-topics-policy-completer # Which [topics to follow automatically](/help/mute-a-topic).  - 1 - Topics the user participates in - 2 - Topics the user sends a message to - 3 - Topics the user starts - 4 - Never  **Changes**: New in Zulip 8.0 (feature level 214).  (e.g. 1)
  --automatically-unmute-topics-in-muted-streams-policy: int@automatically-unmute-topics-in-muted-streams-policy-completer # Which [topics to unmute automatically in muted channels](/help/mute-a-topic).  - 1 - Topics the user participates in - 2 - Topics the user sends a message to - 3 - Topics the user starts - 4 - Never  **Changes**: New in Zulip 8.0 (feature level 214).  (e.g. 1)
  --automatically-follow-topics-where-mentioned: oneof<nothing, bool> # Whether the server will automatically mark the user as following topics where the user is mentioned.  **Changes**: New in Zulip 8.0 (feature level 235).  (e.g. true)
  --resolved-topic-notice-auto-read-policy: string@resolved-topic-notice-auto-read-policy-completer # Controls whether the resolved-topic notices are marked as read.  - "always" - Always mark resolved-topic notices as read. - "except_followed" - Mark resolved-topic notices as read in topics not followed by the user. - "never" - Never mark resolved-topic notices as read.  **Changes**: New in Zulip 11.0 (feature level 385).  (e.g. except_followed)
  --presence-enabled: oneof<nothing, bool> # Display the presence status to other users when online.  (e.g. true)
  --enter-sends: oneof<nothing, bool> # Whether pressing Enter in the compose box sends a message (or saves a message edit).  (e.g. true)
  --twenty-four-hour-time: oneof<nothing, bool> # Whether time should be [displayed in 24-hour notation](/help/change-the-time-format).  **Changes**: New in Zulip 5.0 (feature level 99). Previously, this default was edited using the `default_twenty_four_hour_time` parameter to the `PATCH /realm` endpoint.  (e.g. true)
  --send-private-typing-notifications: oneof<nothing, bool> # Whether [typing notifications](/help/typing-notifications) be sent when composing direct messages.  **Changes**: New in Zulip 5.0 (feature level 105).  (e.g. true)
  --send-stream-typing-notifications: oneof<nothing, bool> # Whether [typing notifications](/help/typing-notifications) be sent when composing channel messages.  **Changes**: New in Zulip 5.0 (feature level 105).  (e.g. true)
  --send-read-receipts: oneof<nothing, bool> # Whether other users are allowed to see whether you've read messages.  **Changes**: New in Zulip 5.0 (feature level 105).  (e.g. true)
  --email-address-visibility: int@email-address-visibility-completer # The [policy][permission-level] for [which other users][help-email-visibility] in this organization can see the user's real email address.  - 1 = Everyone - 2 = Members only - 3 = Administrators only - 4 = Nobody - 5 = Moderators only  **Changes**: New in Zulip 7.0 (feature level 163), replacing the realm-level setting.  [permission-level]: /api/roles-and-permissions#permission-levels [help-email-visibility]: /help/configure-email-visibility  (e.g. 1)
  --web-navigate-to-sent-message: oneof<nothing, bool> # Web/desktop app setting for whether the user's view should automatically go to the conversation where they sent a message.  **Changes**: New in Zulip 9.0 (feature level 268). Previously, this behavior was not configurable.  (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/user_settings_defaults")
  let body = {starred_message_counts: $starred_message_counts, receives_typing_notifications: $receives_typing_notifications, web_suggest_update_timezone: $web_suggest_update_timezone, fluid_layout_width: $fluid_layout_width, high_contrast_mode: $high_contrast_mode, web_mark_read_on_scroll_policy: $web_mark_read_on_scroll_policy, web_channel_default_view: $web_channel_default_view, web_font_size_px: $web_font_size_px, web_line_height_percent: $web_line_height_percent, color_scheme: $color_scheme, enable_drafts_synchronization: $enable_drafts_synchronization, translate_emoticons: $translate_emoticons, display_emoji_reaction_users: $display_emoji_reaction_users, web_home_view: $web_home_view, web_escape_navigates_to_home_view: $web_escape_navigates_to_home_view, left_side_userlist: $left_side_userlist, emojiset: $emojiset, demote_inactive_streams: $demote_inactive_streams, user_list_style: $user_list_style, web_animate_image_previews: $web_animate_image_previews, web_stream_unreads_count_display_policy: $web_stream_unreads_count_display_policy, hide_ai_features: $hide_ai_features, web_inbox_show_channel_folders: $web_inbox_show_channel_folders, web_left_sidebar_show_channel_folders: $web_left_sidebar_show_channel_folders, web_left_sidebar_unreads_count_summary: $web_left_sidebar_unreads_count_summary, enable_stream_desktop_notifications: $enable_stream_desktop_notifications, enable_stream_email_notifications: $enable_stream_email_notifications, enable_stream_push_notifications: $enable_stream_push_notifications, enable_stream_audible_notifications: $enable_stream_audible_notifications, notification_sound: $notification_sound, enable_desktop_notifications: $enable_desktop_notifications, enable_sounds: $enable_sounds, enable_followed_topic_desktop_notifications: $enable_followed_topic_desktop_notifications, enable_followed_topic_email_notifications: $enable_followed_topic_email_notifications, enable_followed_topic_push_notifications: $enable_followed_topic_push_notifications, enable_followed_topic_audible_notifications: $enable_followed_topic_audible_notifications, email_notifications_batching_period_seconds: $email_notifications_batching_period_seconds, enable_offline_email_notifications: $enable_offline_email_notifications, enable_offline_push_notifications: $enable_offline_push_notifications, enable_online_push_notifications: $enable_online_push_notifications, enable_digest_emails: $enable_digest_emails, message_content_in_email_notifications: $message_content_in_email_notifications, pm_content_in_desktop_notifications: $pm_content_in_desktop_notifications, wildcard_mentions_notify: $wildcard_mentions_notify, enable_followed_topic_wildcard_mentions_notify: $enable_followed_topic_wildcard_mentions_notify, desktop_icon_count_display: $desktop_icon_count_display, realm_name_in_email_notifications_policy: $realm_name_in_email_notifications_policy, automatically_follow_topics_policy: $automatically_follow_topics_policy, automatically_unmute_topics_in_muted_streams_policy: $automatically_unmute_topics_in_muted_streams_policy, automatically_follow_topics_where_mentioned: $automatically_follow_topics_where_mentioned, resolved_topic_notice_auto_read_policy: $resolved_topic_notice_auto_read_policy, presence_enabled: $presence_enabled, enter_sends: $enter_sends, twenty_four_hour_time: $twenty_four_hour_time, send_private_typing_notifications: $send_private_typing_notifications, send_stream_typing_notifications: $send_stream_typing_notifications, send_read_receipts: $send_read_receipts, email_address_visibility: $email_address_visibility, web_navigate_to_sent_message: $web_navigate_to_sent_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Bulk update subscription settings
#
# POST /users/me/subscriptions/properties
# operationId: update-subscription-settings
# --subscription_data item shape: {stream_id: int, property: "color"|"is_muted"|"in_home_view"|"pin_to_top"|"desktop_notifications"|"audible_notifications"|"push_notifications"|"email_notifications"|"wildcard_mentions_notify", value: any}
export def "users-me-subscriptions-properties update-subscription-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscription_data: list # A list of objects that describe the changes that should be applied in each subscription. Each object represents a subscription, and must have a `stream_id` key that identifies the channel, as well as the `property` being modified and its new `value`.  (e.g. [{stream_id: 1, property: pin_to_top, value: true}, {stream_id: 3, property: color, value: #f00f00}]) — item shape: {stream_id: int, property: "color"|"is_muted"|"in_home_view"|"pin_to_top"|"desktop_notifications"|"audible_notifications"|"push_notifications"|"email_notifications"|"wildcard_mentions_notify", value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/subscriptions/properties")
  let body = {subscription_data: $subscription_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update a subscription setting
#
# PATCH /users/me/subscriptions/{stream_id}
# operationId: update-subscription-property
export def "users-me-subscriptions update-subscription-property" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  property: string@property-completer # One of the channel properties described below:  - `"color"`: The hex value of the user's display color for the channel.  - `"is_muted"`: Whether the channel is [muted](/help/mute-a-channel).<br>   **Changes**: As of Zulip 6.0 (feature level 139), updating either   `"is_muted"` or `"in_home_view"` generates two [subscription update   events](/api/get-events#subscription-update), one for each property,   that are sent to clients. Prior to this feature level, updating either   property only generated a subscription update event for   `"in_home_view"`. <br>   Prior to Zulip 2.1.0, this feature was represented   by the more confusingly named `"in_home_view"` (with the   opposite value: `in_home_view=!is_muted`); for   backwards-compatibility, modern Zulip still accepts that property.  - `"pin_to_top"`: Whether to pin the channel at the top of the channel list.  - `"desktop_notifications"`: Whether to show desktop notifications   for all messages sent to the channel.  - `"audible_notifications"`: Whether to play a sound   notification for all messages sent to the channel.  - `"push_notifications"`: Whether to trigger a mobile push   notification for all messages sent to the channel.  - `"email_notifications"`: Whether to trigger an email   notification for all messages sent to the channel.  - `"wildcard_mentions_notify"`: Whether wildcard mentions trigger   notifications as though they were personal mentions in this channel.  (e.g. pin_to_top)
  value: any # The new value of the property being modified.  If the property is `"color"`, then `value` is a string representing the hex value of the user's display color for the channel. For all other above properties, `value` is a boolean.  (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/me/subscriptions/($stream_id)")
  let body = {property: $property, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a user by email
#
# GET /users/{email}
# operationId: get-user-by-email
export def "users get-user-by-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-gravatar: oneof<nothing, bool> # Whether the client supports computing gravatars URLs. If enabled, `avatar_url` will be included in the response only if there is a Zulip avatar, and will be `null` for users who are using gravatar as their avatar. This option significantly reduces the compressed size of user data, since gravatar URLs are long, random strings and thus do not compress well. The `client_gravatar` field is set to `true` if clients can compute their own gravatars.  **Changes**: The default value of this parameter was `false` prior to Zulip 5.0 (feature level 92).  (default: true, e.g. false)
  --include-custom-profile-fields: oneof<nothing, bool> # Whether the client wants [custom profile field](/help/custom-profile-fields) data to be included in the response.  **Changes**: New in Zulip 2.1.0. Previous versions do not offer these data via the API.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, user: record<user_id: any, delivery_email: any, email: any, full_name: any, date_joined: any, is_active: any, is_owner: any, is_admin: any, is_guest: any, is_bot: any, bot_type: any, bot_owner_id: any, role: any, timezone: any, avatar_url: any, avatar_version: any, is_imported_stub: any, is_deleted: any, profile_data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_gravatar" $client_gravatar "scalar") (serialize-qp "include_custom_profile_fields" $include_custom_profile_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($email)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user by email
#
# PATCH /users/{email}
# operationId: update-user-by-email
# --profile_data item shape: {id: int, value: any}
export def "users update-user-by-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full-name: string # The user's full name.  **Changes**: Removed unnecessary JSON-encoding of this parameter in Zulip 5.0 (feature level 106).  (e.g. NewName)
  --role: int # New [role](/api/roles-and-permissions) for the user. Roles are encoded as:  - Organization owner: 100 - Organization administrator: 200 - Organization moderator: 300 - Member: 400 - Guest: 600  Only organization owners can add or remove the owner role.  The owner role cannot be removed from the only organization owner.  **Changes**: New in Zulip 3.0 (feature level 8), replacing the previous pair of `is_admin` and `is_guest` boolean parameters. Organization moderator role added in Zulip 4.0 (feature level 60).  (e.g. 400)
  --profile-data: list # An array of objects describing updates to the [custom profile field](/help/custom-profile-fields) data for the user.  (e.g. [{id: 4, value: 0}, {id: 5, value: 1909-04-05}]) — item shape: {id: int, value: any}
  --new-email: string # New email address for the user. Requires the user making the request to be an organization owner and additionally have the `.can_change_user_emails` special permission.  **Changes**: New in Zulip 10.0 (feature level 285).  (e.g. username@example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($email)")
  let body = {full_name: $full_name, role: $role, profile_data: $profile_data, new_email: $new_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a user
#
# GET /users/{user_id}
# operationId: get-user
export def "users get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-gravatar: oneof<nothing, bool> # Whether the client supports computing gravatars URLs. If enabled, `avatar_url` will be included in the response only if there is a Zulip avatar, and will be `null` for users who are using gravatar as their avatar. This option significantly reduces the compressed size of user data, since gravatar URLs are long, random strings and thus do not compress well. The `client_gravatar` field is set to `true` if clients can compute their own gravatars.  **Changes**: The default value of this parameter was `false` prior to Zulip 5.0 (feature level 92).  (default: true, e.g. false)
  --include-custom-profile-fields: oneof<nothing, bool> # Whether the client wants [custom profile field](/help/custom-profile-fields) data to be included in the response.  **Changes**: New in Zulip 2.1.0. Previous versions do not offer these data via the API.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, user: record<user_id: any, delivery_email: any, email: any, full_name: any, date_joined: any, is_active: any, is_owner: any, is_admin: any, is_guest: any, is_bot: any, bot_type: any, bot_owner_id: any, role: any, timezone: any, avatar_url: any, avatar_version: any, is_imported_stub: any, is_deleted: any, profile_data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_gravatar" $client_gravatar "scalar") (serialize-qp "include_custom_profile_fields" $include_custom_profile_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{user_id}
# operationId: update-user
# --profile_data item shape: {id: int, value: any}
export def "users update-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full-name: string # The user's full name.  **Changes**: Removed unnecessary JSON-encoding of this parameter in Zulip 5.0 (feature level 106).  (e.g. NewName)
  --role: int # New [role](/api/roles-and-permissions) for the user. Roles are encoded as:  - Organization owner: 100 - Organization administrator: 200 - Organization moderator: 300 - Member: 400 - Guest: 600  Only organization owners can add or remove the owner role.  The owner role cannot be removed from the only organization owner.  **Changes**: New in Zulip 3.0 (feature level 8), replacing the previous pair of `is_admin` and `is_guest` boolean parameters. Organization moderator role added in Zulip 4.0 (feature level 60).  (e.g. 400)
  --profile-data: list # An array of objects describing updates to the [custom profile field](/help/custom-profile-fields) data for the user.  (e.g. [{id: 4, value: 0}, {id: 5, value: 1909-04-05}]) — item shape: {id: int, value: any}
  --new-email: string # New email address for the user. Requires the user making the request to be an organization owner and additionally have the `.can_change_user_emails` special permission.  **Changes**: New in Zulip 10.0 (feature level 285).  (e.g. username@example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let body = {full_name: $full_name, role: $role, profile_data: $profile_data, new_email: $new_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deactivate a user
#
# DELETE /users/{user_id}
# operationId: deactivate-user
export def "users deactivate-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actions: string # Additional actions for the server to perform while deactivating the user.  As with the actual deactivation, actions are first applied to any bots controlled by the target user, and then to the target user.  **Changes**: New in Zulip 12.0 (feature level 459).
  --deactivation-notification-comment: string # If not `null`, requests that the deactivated user receive a notification email about their account deactivation.  If not `""`, encodes custom text written by the administrator to be included in the notification email.  **Changes**: New in Zulip 5.0 (feature level 135).  (e.g. Farewell! )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "actions" $actions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)" $qp)
  let body = {deactivation_notification_comment: $deactivation_notification_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get linkifiers
#
# GET /realm/linkifiers
# operationId: get-linkifiers
export def "realm-linkifiers get-linkifiers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, linkifiers: table<pattern: string, url_template: string, id: int, example_input: string, reverse_template: string, alternative_url_templates: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/linkifiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reorder linkifiers
#
# PATCH /realm/linkifiers
# operationId: reorder-linkifiers
export def "realm-linkifiers reorder-linkifiers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ordered_linkifier_ids: list # A list of the IDs of all the linkifiers defined in this organization, in the desired new order.  (e.g. [3, 2, 1, 5])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/linkifiers")
  let body = {ordered_linkifier_ids: $ordered_linkifier_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add a linkifier
#
# POST /realm/filters
# operationId: add-linkifier
export def "realm-filters add-linkifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pattern: string # The [Python regular expression](https://docs.python.org/3/howto/regex.html) that should trigger the linkifier.  (e.g. #(?P<id>[0-9]+))
  url_template: string # The [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html) compliant URL template used for the link. If you used named groups in `pattern`, you can insert their content here with `{name_of_group}`.  **Changes**: New in Zulip 7.0 (feature level 176). This replaced the `url_format_string` parameter, which was a format string in which named groups' content could be inserted with `%(name_of_group)s`.  (e.g. https://github.com/zulip/zulip/issues/{id})
  --example-input: string # An example input string that matches the linkifier's pattern. This is required for reverse linkifiers.  **Changes**: New in Zulip 12.0 (feature level 471).  (nullable, e.g. #1234)
  --reverse-template: string # A simple template using `{variable}` for variables that can be used to generate the Markdown linkifier syntax, given a URL matching the URL template.  `{{ "{{/}}" }}` can be used for literal `{/}` characters.  Server verifies that variables extracted from example_input using url_pattern when passed to reverse_template returns example_input back to us.  **Changes**: New in Zulip 12.0 (feature level 471).  (nullable, e.g. #{id})
  --alternative-url-templates: list # An array of additional [RFC 6570][rfc6570] compliant URL template strings that are used for reverse linkification (converting pasted URLs to linkifier pattern text). These templates have no effect on forward linkification.  [rfc6570]: https://www.rfc-editor.org/rfc/rfc6570.html  **Changes**: New in Zulip 12.0 (feature level e2b257).  (e.g. [https://github.com/zulip/zulip/pull/{id}])
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/filters")
  let body = {pattern: $pattern, url_template: $url_template, example_input: $example_input, reverse_template: $reverse_template, alternative_url_templates: $alternative_url_templates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a linkifier
#
# DELETE /realm/filters/{filter_id}
# operationId: remove-linkifier
export def "realm-filters remove-linkifier" [
  filter_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realm/filters/($filter_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a linkifier
#
# PATCH /realm/filters/{filter_id}
# operationId: update-linkifier
export def "realm-filters update-linkifier" [
  filter_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pattern: string # The [Python regular expression](https://docs.python.org/3/howto/regex.html) that should trigger the linkifier.  (e.g. #(?P<id>[0-9]+))
  url_template: string # The [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html) compliant URL template used for the link. If you used named groups in `pattern`, you can insert their content here with `{name_of_group}`.  **Changes**: New in Zulip 7.0 (feature level 176). This replaced the `url_format_string` parameter, which was a format string in which named groups' content could be inserted with `%(name_of_group)s`.  (e.g. https://github.com/zulip/zulip/issues/{id})
  --example-input: string # An example input string that matches the linkifier's pattern. This is required for reverse linkifiers. Passing an empty string will set this field back to null.  **Changes**: New in Zulip 12.0 (feature level 471).  (nullable, e.g. #1234)
  --reverse-template: string # A simple template using `{variable}` for variables that can be used to generate the Markdown linkifier syntax, given a URL matching the URL template. Passing an empty string will set this field back to null.  Server verifies that variables extracted from example_input using url_pattern when passed to reverse_template returns example_input back to us.  `{{ "{{/}}" }}` can be used for literal `{/}` characters.  **Changes**: New in Zulip 12.0 (feature level 471).  (nullable, e.g. #{id})
  --alternative-url-templates: list # An array of additional [RFC 6570][rfc6570] compliant URL template strings that are used for reverse linkification (converting pasted URLs to linkifier pattern text). These templates have no effect on forward linkification.  [rfc6570]: https://www.rfc-editor.org/rfc/rfc6570.html  **Changes**: New in Zulip 12.0 (feature level e2b257).  (e.g. [https://github.com/zulip/zulip/pull/{id}])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realm/filters/($filter_id)")
  let body = {pattern: $pattern, url_template: $url_template, example_input: $example_input, reverse_template: $reverse_template, alternative_url_templates: $alternative_url_templates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add a code playground
#
# POST /realm/playgrounds
# operationId: add-code-playground
export def "realm-playgrounds add-code-playground" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The user-visible display name of the playground which can be used to pick the target playground, especially when multiple playground options exist for that programming language.  (e.g. Python playground)
  pygments_language: string # The name of the Pygments language lexer for that programming language.  (e.g. Python)
  url_template: string # The [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html) compliant URL template for the playground. The template should contain exactly one variable named `code`, which determines how the extracted code should be substituted in the playground URL.  **Changes**: New in Zulip 8.0 (feature level 196). This replaced the `url_prefix` parameter, which was used to construct URLs by just concatenating `url_prefix` and `code`.  (e.g. https://python.example.com?code={code})
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/playgrounds")
  let body = {name: $name, pygments_language: $pygments_language, url_template: $url_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a code playground
#
# DELETE /realm/playgrounds/{playground_id}
# operationId: remove-code-playground
export def "realm-playgrounds remove-code-playground" [
  playground_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realm/playgrounds/($playground_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all data exports
#
# GET /export/realm
# operationId: get-realm-exports
export def "export-realm get-realm-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, exports: table<id: int, acting_user_id: int, export_time: float, deleted_timestamp: float, failed_timestamp: float, export_url: string, pending: bool, export_from_prior_server: bool, export_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a data export
#
# POST /export/realm
# operationId: export-realm
export def "export-realm export-realm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --export-type: string@export-type-completer # Whether the data export should be public, full with consent, or full without consent.  - `public` = Public data only export. - `full_with_consent` = Public and private data export (with consent), which includes   private data for users who have granted consent. - `full_without_consent` = All public and private data export, which includes private data for   all users. This option requires the organization to have   the `owner_full_content_access` feature enabled.  If not specified, defaults to `public`.  **Changes**: Zulip 12.0 (feature level 449) changed the type of this field from int to string with `1` being replaced by `public` and `2` being replaced by `full_with_consent`. The option `full_without_consent` was added for full exports without member consent.  **Changes**: New in Zulip 10.0 (feature level 304). Previously, all export requests were public data exports.  (default: public, e.g. full_with_consent)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/realm")
  let body = {export_type: $export_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get data export consent state
#
# GET /export/realm/consents
# operationId: get-realm-export-consents
export def "export-realm-consents get-realm-export-consents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, export_consents: table<user_id: int, consented: bool, email_address_visibility: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/realm/consents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all invitations
#
# GET /invites
# operationId: get-invites
export def "invites get-invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, invites: table<id: int, invited_by_user_id: int, invited: int, expiry_date: int, invited_as: int, email: string, notify_referrer_on_join: bool, link_url: string, is_multiuse: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send invitations
#
# POST /invites
# operationId: send-invites
export def "invites send-invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invitee_emails: string # The string containing the email addresses, separated by commas or newlines, that will be sent an invitation.  (e.g. example@zulip.com, logan@zulip.com)
  --invite-expires-in-minutes: int # The number of minutes before the invitation will expire. If `null`, the invitation will never expire. If unspecified, the server will use a default value (based on the `INVITATION_LINK_VALIDITY_MINUTES` server setting, which defaults to 14400, i.e. 10 days) for when the invitation will expire.  **Changes**: New in Zulip 6.0 (feature level 126). Previously, there was an `invite_expires_in_days` parameter, which specified the duration in days instead of minutes.  (nullable, e.g. 14400)
  --invite-as: int@invite-as-completer # The [organization-level role](/api/roles-and-permissions) of the user that is created when the invitation is accepted. Possible values are:  - 100 = Organization owner - 200 = Organization administrator - 300 = Organization moderator - 400 = Member - 600 = Guest  Users can only create invitation links for [roles with equal or stricter restrictions](/api/roles-and-permissions#permission-levels) as their own. For example, a moderator cannot invite someone to be an owner or administrator, but they can invite them to be a moderator or member.  **Changes**: In Zulip 4.0 (feature level 61), added support for inviting users as moderators.  (default: 400, e.g. 600)
  stream_ids: list # A list containing the [IDs of the channels](/api/get-stream-id) that the newly created user will be automatically subscribed to if the invitation is accepted, in addition to any default channels that the new user may be subscribed to based on the `include_realm_default_subscriptions` parameter.  Requested channels must either be default channels for the organization, or ones the acting user has permission to add subscribers to.  This list must be empty if the current user has the unlikely configuration of being able to send invitations while lacking permission to [subscribe other users to channels][can-subscribe-others].  **Changes**: Prior to Zulip 10.0 (feature level 342), default channels that the acting user did not directly have permission to add subscribers to would be rejected.  Before Zulip 7.0 (feature level 180), specifying `stream_ids` as an empty list resulted in an error.  [can-subscribe-others]: /help/configure-who-can-invite-to-channels  (e.g. [1, 10])
  --group-ids: list # A list containing the [IDs of the user groups](/api/get-user-groups) that the newly created user will be automatically added to if the invitation is accepted. If the list is empty, then the new user will not be added to any user groups. The acting user must have permission to add users to the groups listed in this request.  **Changes**: New in Zulip 10.0 (feature level 322).  (e.g. [])
  --include-realm-default-subscriptions: oneof<nothing, bool> # Boolean indicating whether the newly created user should be subscribed to the [default channels][default-channels] for the organization.  Note that this parameter can be `true` even if the user creating the invitation does not generally have permission to [subscribe other users to channels][can-subscribe-others].  **Changes**: New in Zulip 9.0 (feature level 261). Previous versions of Zulip behaved as though this parameter was always `false`; clients needed to include the organization's default channels in the `stream_ids` parameter for a newly created user to be automatically subscribed to them.  [default-channels]: /help/set-default-channels-for-new-users [can-subscribe-others]: /help/configure-who-can-invite-to-channels  (default: false, e.g. false)
  --notify-referrer-on-join: oneof<nothing, bool> # A boolean indicating whether the referrer would like to receive a direct message from [notification bot](/help/configure-automated-notices) when a user account is created using this invitation.  **Changes**: New in Zulip 9.0 (feature level 267). Previously, referrers always received such direct messages.  (default: true, e.g. false)
  --welcome-message-custom-text: string # Custom message text, in Zulip Markdown format, to be sent by the Welcome Bot to new users that join the organization via this invitation.  Maximum length is 8000 Unicode code points.  Only organization administrators can use this feature; for other users, the value is always `null`.  - `null`: the organization's default `welcome_message_custom_text` is used. - Empty string: no Welcome Bot custom message is sent. - Otherwise, the provided string is the custom message.  **Changes**: New in Zulip 11.0 (feature level 416).  (nullable, e.g. Welcome to Zulip! We're excited to have you on board.)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invites")
  let body = {invitee_emails: $invitee_emails, invite_expires_in_minutes: $invite_expires_in_minutes, invite_as: $invite_as, stream_ids: $stream_ids, group_ids: $group_ids, include_realm_default_subscriptions: $include_realm_default_subscriptions, notify_referrer_on_join: $notify_referrer_on_join, welcome_message_custom_text: $welcome_message_custom_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a reusable invitation link
#
# POST /invites/multiuse
# operationId: create-invite-link
export def "invites-multiuse create-invite-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invite-expires-in-minutes: int # The number of minutes before the invitation will expire. If `null`, the invitation will never expire. If unspecified, the server will use a default value (based on the `INVITATION_LINK_VALIDITY_MINUTES` server setting, which defaults to 14400, i.e. 10 days) for when the invitation will expire.  **Changes**: New in Zulip 6.0 (feature level 126). Previously, there was an `invite_expires_in_days` parameter, which specified the duration in days instead of minutes.  (nullable, e.g. 14400)
  --invite-as: int@invite-as-completer # The [organization-level role](/api/roles-and-permissions) of the user that is created when the invitation is accepted. Possible values are:  - 100 = Organization owner - 200 = Organization administrator - 300 = Organization moderator - 400 = Member - 600 = Guest  Users can only create invitation links for [roles with equal or stricter restrictions](/api/roles-and-permissions#permission-levels) as their own. For example, a moderator cannot invite someone to be an owner or administrator, but they can invite them to be a moderator or member.  **Changes**: In Zulip 4.0 (feature level 61), added support for inviting users as moderators.  (default: 400, e.g. 600)
  --stream-ids: list # A list containing the [IDs of the channels](/api/get-stream-id) that the newly created user will be automatically subscribed to if the invitation is accepted, in addition to any default channels that the new user may be subscribed to based on the `include_realm_default_subscriptions` parameter.  Requested channels must either be default channels for the organization, or ones the acting user has permission to add subscribers to.  This list must be empty if the current user has the unlikely configuration of being able to create reusable invitation links while lacking permission to [subscribe other users to channels][can-subscribe-others].  **Changes**: Prior to Zulip 10.0 (feature level 342), default channels that the acting user did not directly have permission to add subscribers to would be rejected.  [can-subscribe-others]: /help/configure-who-can-invite-to-channels  (default: [], e.g. [1, 10])
  --group-ids: list # A list containing the [IDs of the user groups](/api/get-user-groups) that the newly created user will be automatically added to if the invitation is accepted. If the list is empty, then the new user will not be added to any user groups. The acting user must have permission to add users to the groups listed in this request.  **Changes**: New in Zulip 10.0 (feature level 322).  (default: [], e.g. [])
  --include-realm-default-subscriptions: oneof<nothing, bool> # Boolean indicating whether the newly created user should be subscribed to the [default channels][default-channels] for the organization.  Note that this parameter can be `true` even if the current user does not generally have permission to [subscribe other users to channels][can-subscribe-others].  **Changes**: New in Zulip 9.0 (feature level 261). Previous versions of Zulip behaved as though this parameter was always `false`; clients needed to include the organization's default channels in the `stream_ids` parameter for a newly created user to be automatically subscribed to them.  [default-channels]: /help/set-default-channels-for-new-users [can-subscribe-others]: /help/configure-who-can-invite-to-channels  (default: false, e.g. false)
  --welcome-message-custom-text: string # Custom message text, in Zulip Markdown format, to be sent by the Welcome Bot to new users that join the organization via this invitation.  Maximum length is 8000 Unicode code points.  Only organization administrators can use this feature; for other users, the value is always `null`.  - `null`: the organization's default `welcome_message_custom_text` is used. - Empty string: no Welcome Bot custom message is sent. - Otherwise, the provided string is the custom message.  **Changes**: New in Zulip 11.0 (feature level 416).  (nullable, e.g. Welcome to Zulip! We're excited to have you on board.)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, invite_link: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invites/multiuse")
  let body = {invite_expires_in_minutes: $invite_expires_in_minutes, invite_as: $invite_as, stream_ids: $stream_ids, group_ids: $group_ids, include_realm_default_subscriptions: $include_realm_default_subscriptions, welcome_message_custom_text: $welcome_message_custom_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Revoke an email invitation
#
# DELETE /invites/{invite_id}
# operationId: revoke-email-invite
export def "invites revoke-email-invite" [
  invite_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invites/($invite_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke a reusable invitation link
#
# DELETE /invites/multiuse/{invite_id}
# operationId: revoke-invite-link
export def "invites-multiuse revoke-invite-link" [
  invite_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invites/multiuse/($invite_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend an email invitation
#
# POST /invites/{invite_id}/resend
# operationId: resend-email-invite
export def "invites-resend resend-email-invite" [
  invite_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invites/($invite_id)/resend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test welcome bot custom message
#
# POST /realm/test_welcome_bot_custom_message
# operationId: test-welcome-bot-custom-message
export def "realm-test-welcome-bot-custom-message test-welcome-bot-custom-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  welcome_message_custom_text: string # Custom message text, in Zulip Markdown format, to be used for this test message.  Maximum length is 8000 Unicode code points.  (e.g. Welcome to Zulip! We're excited to have you on board.)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, message_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realm/test_welcome_bot_custom_message")
  let body = {welcome_message_custom_text: $welcome_message_custom_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Register an event queue
#
# POST /register
# operationId: register-queue
export def "register register-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apply-markdown: oneof<nothing, bool> # Set to `true` if you would like the content to be rendered in HTML format (otherwise the API will return the raw text that the user entered)  (default: false, e.g. true)
  --client-gravatar: oneof<nothing, bool> # Whether the client supports computing gravatars URLs. If enabled, `avatar_url` will be included in the response only if there is a Zulip avatar, and will be `null` for users who are using gravatar as their avatar. This option significantly reduces the compressed size of user data, since gravatar URLs are long, random strings and thus do not compress well. The `client_gravatar` field is set to `true` if clients can compute their own gravatars.  The default value is `true` for authenticated requests and `false` for [unauthenticated requests](/help/public-access-option). Passing `true` in an unauthenticated request is an error.  **Changes**: Before Zulip 6.0 (feature level 149), this parameter was silently ignored and processed as though it were `false` in unauthenticated requests.  (e.g. false)
  --include-subscribers: string@include-subscribers-completer # Whether each returned channel object should include a `subscribers` field containing a list of the user IDs of its subscribers.  Client apps supporting organizations with many thousands of users should not pass `true`, because the full subscriber matrix may be several megabytes of data. The `partial` value, combined with the `subscriber_count` and fetching subscribers for individual channels as needed, is recommended to support client app features where channel subscriber data is useful.  If a client passes `partial` for this parameter, the server may, for some channels, return a subset of the channel's subscribers in the `partial_subscribers` field instead of the `subscribers` field, which always contains the complete set of subscribers.  The server guarantees that it will always return a `subscribers` field for channels with fewer than 250 total subscribers. When returning a `partial_subscribers` field, the server guarantees that all bot users and users active within the last 14 days will be included. For other cases, the server may use its discretion to determine which channels and users to include, balancing between payload size and usefulness of the data provided to the client.  Passing `true` in an [unauthenticated request](/help/public-access-option) is an error.  **Changes**: The `partial` value is new in Zulip 11.0 (feature level 412).  Before Zulip 6.0 (feature level 149), this parameter was silently ignored and processed as though it were `false` in unauthenticated requests.  New in Zulip 2.1.0.  (default: false, e.g. true)
  --slim-presence: oneof<nothing, bool> # If `true`, the `presences` object returned in the response will be keyed by user ID and the entry for each user's presence data will be in the modern format.  **Changes**: New in Zulip 3.0 (no feature level; API unstable).  (default: false, e.g. true)
  --presence-history-limit-days: int # Limits how far back in time to fetch user presence data. If not specified, defaults to 14 days. A value of N means that the oldest presence data fetched will be from at most N days ago.  **Changes**: New in Zulip 10.0 (feature level 288).  (e.g. 365)
  --event-types: list # A JSON-encoded array indicating which types of events you're interested in. Values that you might find useful include:  - **message** (messages) - **subscription** (changes in your subscriptions) - **realm_user** (changes to users in the organization and   their properties, such as their name).  If you do not specify this parameter, you will receive all events, and have to filter out the events not relevant to your client in your client code. For most applications, one is only interested in messages, so one specifies: `"event_types": ["message"]`  Event types not supported by the server are ignored, in order to simplify the implementation of client apps that support multiple server versions.  (e.g. [message])
  --all-public-streams: oneof<nothing, bool> # Whether you would like to request message events from all public channels. Useful for workflow bots that you'd like to see all new messages sent to public channels. (You can also subscribe the user to private channels).  (default: false, e.g. true)
  --client-capabilities: record # Dictionary containing details on features the client supports that are relevant to the format of responses sent by the server.  - `notification_settings_null`: Boolean for whether the   client can handle the current API with `null` values for   channel-level notification settings (which means the channel   is not customized and should inherit the user's global   notification settings for channel messages).   <br />   **Changes**: New in Zulip 2.1.0. In earlier Zulip releases,   channel-level notification settings were simple booleans.  - `bulk_message_deletion`: Boolean for whether the client's   handler for the `delete_message` event type has been   updated to process the new bulk format (with a   `message_ids`, rather than a singleton `message_id`).   Otherwise, the server will send `delete_message` events   in a loop.   <br />   **Changes**: New in Zulip 3.0 (feature level 13). This   capability is for backwards-compatibility; it will be   required in a future server release.  - `user_avatar_url_field_optional`: Boolean for whether the   client required avatar URLs for all users, or supports   using `GET /avatar/{user_id}` to access user avatars. If the   client has this capability, the server may skip sending a   `avatar_url` field in the `realm_user` at its sole discretion   to optimize network performance. This is an important optimization   in organizations with 10,000s of users.   <br />   **Changes**: New in Zulip 3.0 (feature level 18).  - `stream_typing_notifications`: Boolean for whether the client   supports channel typing notifications.   <br />   **Changes**: New in Zulip 4.0 (feature level 58). This capability is   for backwards-compatibility; it will be required in a   future server release.  - `user_settings_object`: Has no effect with modern servers. Previously,   this was a boolean for whether the client supported the modern   [`user_settings` event type](/api/get-events#user_settings-update) and   the top-level `user_settings` object in this endpoint's response.   <br />   **Changes**: Prior to Zulip 12.0 (feature level 439), if false, the   server would additionally send the legacy `update_global_notifications`   and `update_display_settings` event types, if requested.   <br />   New in Zulip 5.0 (feature level 89). Because the feature level 89 API   changes were merged together, clients could safely make a request with   this client capability, and also request all three event types   (`user_settings`, `update_display_settings`, and   `update_global_notifications`), and then use the `zulip_feature_level`   in this endpoint's response or the presence/absence of a `user_settings`   key to determine where to look for the data.  - `linkifier_url_template`: Boolean for whether the client accepts   [linkifiers][help-linkifiers] that use [RFC 6570][rfc6570] compliant   URL templates for linkifying matches. If false or unset, then the   `realm_linkifiers` array in the `/register` response will be empty   if present, and no `realm_linkifiers` [events][events-linkifiers]   will be sent to the client.   <br />   **Changes**: New in Zulip 7.0 (feature level 176). This capability   is for backwards-compatibility.  - `user_list_incomplete`: Boolean for whether the client supports not having an   incomplete user database. If true, then the `realm_users` array in the `register`   response will not include data for inaccessible users and clients of guest users will   not receive `realm_user op:add` events for newly created users that are not accessible   to the current user.   <br />   **Changes**: New in Zulip 8.0 (feature level 232). This   capability is for backwards-compatibility.  - `include_deactivated_groups`: Boolean for whether the client can handle   deactivated user groups by themselves. If false, then the `realm_user_groups`   array in the `/register` response will only include active groups, clients   will receive a `remove` event instead of `update` event when a group is   deactivated and no `update` event will be sent to the client if a deactivated   user group is renamed.   <br />   **Changes**: New in Zulip 10.0 (feature level 294). This   capability is for backwards-compatibility.  - `archived_channels`: Boolean for whether the client supports processing   [archived channels](/help/archive-a-channel) in the `stream` and   `subscription` event types. If `false`, the server will not include data   related to archived channels in the `register` response or in events.   <br />   **Changes**: New in Zulip 10.0 (feature level 315). This allows clients to   access archived channels, without breaking backwards-compatibility for   existing clients.  - `empty_topic_name`: Boolean for whether the client supports processing   the empty string as a topic name. Clients not declaring this capability   will be sent the value of `realm_empty_topic_display_name` found in the   [POST /register](/api/register-queue) response instead of the empty string   wherever topic names appear in the register response or events involving   topic names.   <br/>   **Changes**: New in Zulip 10.0 (feature level 334). Previously,   the empty string was not a valid topic name.  - `simplified_presence_events`: Boolean for whether the client supports   receiving the [`presence` event type](/api/get-events#presence) with   user presence data in the modern format. If true, the server will   send these events with the `presences` field that has the user presence   data in the modern format. Otherwise, these event will contain fields   with legacy format user presence data.   <br />   **Changes**: New in Zulip 11.0 (feature level 419).  - `individual_emoji_changes`: Boolean for whether the client supports   receiving the [`realm_emoji/add` and `realm_emoji/edit` event   types](/api/get-events#realm_emoji-add). If true, the server will   send individual `realm_emoji/add` events when a custom emoji is   added, and `realm_emoji/edit` events when a custom emoji's   properties are changed (e.g., deactivated). Otherwise, the server   will send the legacy `realm_emoji/update` event containing all   custom emoji for the organization.   <br />   **Changes**: New in Zulip 12.0 (feature level 491).  [help-linkifiers]: /help/add-a-custom-linkifier [rfc6570]: https://www.rfc-editor.org/rfc/rfc6570.html [events-linkifiers]: /api/get-events#realm_linkifiers  (e.g. {notification_settings_null: true})
  --fetch-event-types: list # Same as the `event_types` parameter except that the values in `fetch_event_types` are used to fetch initial data. If `fetch_event_types` is not provided, `event_types` is used and if `event_types` is not provided, this parameter defaults to `null`.  Event types not supported by the server are ignored, in order to simplify the implementation of client apps that support multiple server versions.  (e.g. [message])
  --narrow: list # A JSON-encoded array of arrays of length 2 indicating the [narrow filter(s)](/api/construct-narrow) for which you'd like to receive events for.  For example, to receive events for direct messages (including group direct messages) received by the user, one can use `"narrow": [["is", "dm"]]`.  Unlike the API for [fetching messages](/api/get-messages), this narrow parameter is simply a filter on messages that the user receives through their channel subscriptions (or because they are a recipient of a direct message).  This means that a client that requests a `narrow` filter of `[["channel", "Denmark"]]` will receive events for new messages sent to that channel while the user is subscribed to that channel. The client will not receive any message events at all if the user is not subscribed to `"Denmark"`.  Newly created bot users are not usually subscribed to any channels, so bots using this API need to be [subscribed](/api/subscribe) to any channels whose messages you'd like them to process using this endpoint.  See the `all_public_streams` parameter for how to process all public channel messages in an organization.  **Changes**: See [changes section](/api/construct-narrow#changes) of search/narrow filter documentation.  (default: [], e.g. [[channel, Denmark]])
  --idle-queue-timeout: any # At least how long (in seconds) the server should keep the event queue alive when the client is not polling. If the client does not poll before this timeout, the queue will eventually be garbage-collected.  Alternatively, the string `"mobile"` can be passed to use the server's recommended timeout for mobile clients. This is currently 12 hours, but may change in the future.  If not specified, the server uses a default of 10 minutes. The maximum allowed value is 7 days.  **Changes**: New in Zulip 12.0 (feature level 481).  (e.g. 3600)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, queue_id: string, idle_queue_timeout_secs: int, last_event_id: int, zulip_feature_level: int, zulip_version: string, zulip_merge_base: string, alert_words: list<string>, custom_profile_fields: table<id: int, type: int, order: int, name: string, hint: string, field_data: string, display_in_profile_summary: bool, required: bool, editable_by_user: bool, use_for_user_matching: bool>, custom_profile_field_types: record, realm_date_created: int, demo_organization_scheduled_deletion_date: int, drafts: table<id: int, type: string, to: list, topic: string, content: string, timestamp: int>, onboarding_steps: table<type: string, name: string>, navigation_tour_video_url: string, max_message_id: int, max_reminder_note_length: int, max_stream_name_length: int, max_stream_description_length: int, max_channel_folder_name_length: int, max_channel_folder_description_length: int, max_topic_length: int, max_message_length: int, server_min_deactivated_realm_deletion_days: int, server_max_deactivated_realm_deletion_days: int, server_presence_ping_interval_seconds: int, server_presence_offline_threshold_seconds: int, server_typing_started_expiry_period_milliseconds: int, server_typing_stopped_wait_period_milliseconds: int, server_typing_started_wait_period_milliseconds: int, scheduled_messages: table<scheduled_message_id: any, type: any, to: any, topic: any, content: any, rendered_content: any, scheduled_delivery_timestamp: any, failed: any>, reminders: table<reminder_id: int, type: string, to: list, content: string, rendered_content: string, scheduled_delivery_timestamp: int, failed: bool, reminder_target_message_id: int>, muted_topics: list<list<any>>, muted_users: table<id: int, timestamp: int>, presences: record, presence_last_update_id: int, server_timestamp: float, realm_domains: table<domain: string, allow_subdomains: bool>, realm_emoji: record, realm_linkifiers: table<pattern: string, url_template: string, id: int>, realm_filters: list<list<any>>, realm_playgrounds: table<id: int, name: string, pygments_language: string, url_template: string>, realm_user_groups: table<name: string, date_created: int, creator_id: int, description: string, members: list, direct_subgroup_ids: list, id: int, is_system_group: bool, can_add_members_group: record, can_join_group: record, can_leave_group: record, can_manage_group: record, can_mention_group: record, can_remove_members_group: record, deactivated: bool>, realm_bots: table<user_id: any, default_sending_stream: any, default_events_register_stream: any, default_all_public_streams: any, services: any>, realm_embedded_bots: table<name: string, config: record>, realm_incoming_webhook_bots: table<name: string, display_name: string, all_event_types: list, config_options: list, url_options: list>, recent_private_conversations: table<max_message_id: int, user_ids: list>, navigation_views: table<fragment: string, is_pinned: bool, name: string>, saved_snippets: table<id: int, title: string, content: string, date_created: int>, subscriptions: table<stream_id: int, name: string, description: string, rendered_description: string, date_created: int, creator_id: int, invite_only: bool, subscribers: list, partial_subscribers: list, desktop_notifications: bool, email_notifications: bool, wildcard_mentions_notify: bool, push_notifications: bool, audible_notifications: bool, pin_to_top: bool, is_muted: bool, in_home_view: bool, is_announcement_only: bool, is_web_public: bool, color: string, stream_post_policy: int, message_retention_days: int, history_public_to_subscribers: bool, first_message_id: int, folder_id: int, topics_policy: string, is_recently_active: bool, stream_weekly_traffic: int, can_add_subscribers_group: record, can_remove_subscribers_group: record, can_administer_channel_group: record, can_delete_any_message_group: record, can_delete_own_message_group: record, can_move_messages_out_of_channel_group: record, can_move_messages_within_channel_group: record, can_send_message_group: record, can_subscribe_group: record, can_resolve_topics_group: record, can_create_topic_group: record, is_archived: bool, subscriber_count: float>, unsubscribed: table<stream_id: int, name: string, description: string, rendered_description: string, date_created: int, creator_id: int, invite_only: bool, subscribers: list, partial_subscribers: list, desktop_notifications: bool, email_notifications: bool, wildcard_mentions_notify: bool, push_notifications: bool, audible_notifications: bool, pin_to_top: bool, is_muted: bool, in_home_view: bool, is_announcement_only: bool, is_web_public: bool, color: string, stream_post_policy: int, message_retention_days: int, history_public_to_subscribers: bool, first_message_id: int, folder_id: int, topics_policy: string, is_recently_active: bool, stream_weekly_traffic: int, can_add_subscribers_group: record, can_remove_subscribers_group: record, can_administer_channel_group: record, can_delete_any_message_group: record, can_delete_own_message_group: record, can_move_messages_out_of_channel_group: record, can_move_messages_within_channel_group: record, can_send_message_group: record, can_subscribe_group: record, can_resolve_topics_group: record, can_create_topic_group: record, is_archived: bool, subscriber_count: float>, never_subscribed: table<stream_id: any, name: any, is_archived: any, description: any, date_created: any, creator_id: any, invite_only: any, rendered_description: any, is_web_public: any, stream_post_policy: any, message_retention_days: any, history_public_to_subscribers: any, topics_policy: any, first_message_id: any, folder_id: any, is_recently_active: any, is_announcement_only: any, can_add_subscribers_group: any, can_remove_subscribers_group: any, can_administer_channel_group: any, can_delete_any_message_group: any, can_delete_own_message_group: any, can_move_messages_out_of_channel_group: any, can_move_messages_within_channel_group: any, can_send_message_group: any, can_subscribe_group: any, can_resolve_topics_group: any, can_create_topic_group: any, subscriber_count: any, stream_weekly_traffic: int, subscribers: list, partial_subscribers: list>, channel_folders: table<id: int, name: string, order: int, date_created: int, creator_id: int, description: string, rendered_description: string, is_archived: bool>, unread_msgs: record<count: int, pms: list<record>, streams: list<record>, huddles: list<record>, mentions: list<int>, old_unreads_missing: bool>, starred_messages: list<int>, streams: table<stream_id: any, name: any, is_archived: any, description: any, date_created: any, creator_id: any, invite_only: any, rendered_description: any, is_web_public: any, stream_post_policy: any, message_retention_days: any, history_public_to_subscribers: any, topics_policy: any, first_message_id: any, folder_id: any, is_recently_active: any, is_announcement_only: any, can_add_subscribers_group: any, can_remove_subscribers_group: any, can_administer_channel_group: any, can_delete_any_message_group: any, can_delete_own_message_group: any, can_move_messages_out_of_channel_group: any, can_move_messages_within_channel_group: any, can_send_message_group: any, can_subscribe_group: any, can_resolve_topics_group: any, can_create_topic_group: any, subscriber_count: any, stream_weekly_traffic: int>, realm_default_streams: list<int>, realm_default_stream_groups: table<name: string, description: string, id: int, streams: list>, stop_words: list<string>, user_status: record, user_settings: record<twenty_four_hour_time: bool, web_mark_read_on_scroll_policy: int, web_channel_default_view: int, starred_message_counts: bool, receives_typing_notifications: bool, web_suggest_update_timezone: bool, fluid_layout_width: bool, high_contrast_mode: bool, web_font_size_px: int, web_line_height_percent: int, color_scheme: int, translate_emoticons: bool, display_emoji_reaction_users: bool, default_language: string, web_home_view: string, web_escape_navigates_to_home_view: bool, left_side_userlist: bool, emojiset: string, demote_inactive_streams: int, user_list_style: int, web_animate_image_previews: string, web_stream_unreads_count_display_policy: int, hide_ai_features: bool, web_inbox_show_channel_folders: bool, web_left_sidebar_show_channel_folders: bool, web_left_sidebar_unreads_count_summary: bool, timezone: string, enter_sends: bool, enable_drafts_synchronization: bool, enable_stream_desktop_notifications: bool, enable_stream_email_notifications: bool, enable_stream_push_notifications: bool, enable_stream_audible_notifications: bool, notification_sound: string, enable_desktop_notifications: bool, enable_sounds: bool, enable_followed_topic_desktop_notifications: bool, enable_followed_topic_email_notifications: bool, enable_followed_topic_push_notifications: bool, enable_followed_topic_audible_notifications: bool, email_notifications_batching_period_seconds: int, enable_offline_email_notifications: bool, enable_offline_push_notifications: bool, enable_online_push_notifications: bool, enable_digest_emails: bool, enable_marketing_emails: bool, enable_login_emails: bool, message_content_in_email_notifications: bool, pm_content_in_desktop_notifications: bool, wildcard_mentions_notify: bool, enable_followed_topic_wildcard_mentions_notify: bool, desktop_icon_count_display: int, realm_name_in_email_notifications_policy: int, automatically_follow_topics_policy: int, automatically_unmute_topics_in_muted_streams_policy: int, automatically_follow_topics_where_mentioned: bool, resolved_topic_notice_auto_read_policy: string, presence_enabled: bool, available_notification_sounds: list<string>, emojiset_choices: list<record>, send_private_typing_notifications: bool, send_stream_typing_notifications: bool, send_read_receipts: bool, allow_private_data_export: bool, email_address_visibility: int, web_navigate_to_sent_message: bool>, user_topics: table<stream_id: int, topic_name: string, last_updated: int, visibility_policy: int>, has_zoom_token: bool, has_webex_token: bool, giphy_api_key: string, tenor_api_key: string, klipy_api_key: string, devices: record, receives_typing_notifications: bool, realm_message_edit_history_visibility_policy: string, realm_allow_edit_history: bool, realm_can_add_custom_emoji_group: record, realm_can_add_subscribers_group: record, realm_can_delete_any_message_group: record, realm_can_delete_own_message_group: record, realm_can_set_delete_message_policy_group: record, realm_can_set_topics_policy_group: record, realm_can_invite_users_group: record, realm_can_mention_many_users_group: record, realm_can_move_messages_between_channels_group: record, realm_can_move_messages_between_topics_group: record, realm_can_create_groups: record, realm_can_create_bots_group: record, realm_can_create_write_only_bots_group: record, realm_can_manage_all_groups: record, realm_can_manage_billing_group: record, realm_can_create_public_channel_group: record, realm_can_create_private_channel_group: record, realm_can_create_web_public_channel_group: record, realm_can_resolve_topics_group: record, realm_create_public_stream_policy: int, realm_create_private_stream_policy: int, realm_create_web_public_stream_policy: int, realm_wildcard_mention_policy: int, realm_default_language: string, realm_welcome_message_custom_text: string, realm_description: string, realm_digest_emails_enabled: bool, realm_disallow_disposable_email_addresses: bool, realm_email_changes_disabled: bool, realm_invite_required: bool, realm_create_multiuse_invite_group: record, realm_media_preview_size: int, realm_inline_image_preview: bool, realm_inline_url_embed_preview: bool, realm_topics_policy: string, realm_mandatory_topics: bool, realm_message_retention_days: int, realm_name: string, realm_require_e2ee_push_notifications: bool, realm_require_unique_names: bool, realm_name_changes_disabled: bool, realm_avatar_changes_disabled: bool, realm_emails_restricted_to_domains: bool, realm_send_channel_events_messages: bool, realm_send_welcome_emails: bool, realm_message_content_allowed_in_email_notifications: bool, realm_enable_spectator_access: bool, realm_want_advertise_in_communities_directory: bool, realm_video_chat_provider: int, realm_jitsi_server_url: string, realm_gif_rating_policy: int, realm_waiting_period_threshold: int, realm_digest_weekday: int, realm_direct_message_initiator_group: record, realm_direct_message_permission_group: record, realm_default_code_block_language: string, realm_message_content_delete_limit_seconds: int, realm_authentication_methods: record, realm_allow_message_editing: bool, realm_message_content_edit_limit_seconds: int, realm_move_messages_within_stream_limit_seconds: int, realm_move_messages_between_streams_limit_seconds: int, realm_enable_read_receipts: bool, realm_icon_url: string, realm_icon_source: string, realm_workplace_users_group: record, max_icon_file_size_mib: int, realm_logo_url: string, realm_logo_source: string, realm_night_logo_url: string, realm_night_logo_source: string, max_logo_file_size_mib: int, realm_bot_domain: string, realm_uri: string, realm_url: string, realm_uuid: string, realm_available_video_chat_providers: record, realm_presence_disabled: bool, settings_send_digest_emails: bool, realm_email_auth_enabled: bool, realm_password_auth_enabled: bool, realm_push_notifications_enabled: bool, realm_push_notifications_enabled_end_timestamp: int, realm_upload_quota_mib: int, realm_org_type: int, realm_owner_full_content_access: bool, realm_plan_type: int, realm_enable_guest_user_dm_warning: bool, realm_enable_guest_user_indicator: bool, realm_can_access_all_users_group: record, realm_can_summarize_topics_group: record, zulip_plan_is_not_limited: bool, upgrade_text_for_wide_organization_logo: string, realm_default_external_accounts: record, realm_default_avatar_source: string, jitsi_server_url: string, development_environment: bool, server_generation: int, password_min_length: int, password_max_length: int, password_min_guesses: int, gif_rating_policy_options: record, max_file_upload_size_mib: int, max_avatar_file_size_mib: int, server_inline_image_preview: bool, server_inline_url_embed_preview: bool, server_thumbnail_formats: table<name: string, max_width: int, max_height: int, format: string, animated: bool>, server_avatar_changes_disabled: bool, server_name_changes_disabled: bool, server_needs_upgrade: bool, server_web_public_streams_enabled: bool, server_emoji_data_url: string, server_jitsi_server_url: string, server_can_summarize_topics: bool, event_queue_longpoll_timeout_seconds: int, realm_billing: record<has_pending_sponsorship_request: bool>, realm_moderation_request_channel_id: int, realm_new_stream_announcements_stream_id: int, realm_signup_announcements_stream_id: int, realm_zulip_update_announcements_stream_id: int, realm_empty_topic_display_name: string, realm_user_settings_defaults: record<twenty_four_hour_time: bool, web_mark_read_on_scroll_policy: int, web_channel_default_view: int, starred_message_counts: bool, receives_typing_notifications: bool, web_suggest_update_timezone: bool, fluid_layout_width: bool, high_contrast_mode: bool, web_font_size_px: int, web_line_height_percent: int, color_scheme: int, translate_emoticons: bool, display_emoji_reaction_users: bool, default_language: string, web_home_view: string, web_escape_navigates_to_home_view: bool, left_side_userlist: bool, emojiset: string, demote_inactive_streams: int, user_list_style: int, web_animate_image_previews: string, web_stream_unreads_count_display_policy: int, hide_ai_features: bool, web_inbox_show_channel_folders: bool, web_left_sidebar_show_channel_folders: bool, web_left_sidebar_unreads_count_summary: bool, enable_stream_desktop_notifications: bool, enable_stream_email_notifications: bool, enable_stream_push_notifications: bool, enable_stream_audible_notifications: bool, notification_sound: string, enable_desktop_notifications: bool, enable_sounds: bool, enable_offline_email_notifications: bool, enable_offline_push_notifications: bool, enable_online_push_notifications: bool, enable_followed_topic_desktop_notifications: bool, enable_followed_topic_email_notifications: bool, enable_followed_topic_push_notifications: bool, enable_followed_topic_audible_notifications: bool, enable_digest_emails: bool, enable_marketing_emails: bool, enable_login_emails: bool, message_content_in_email_notifications: bool, pm_content_in_desktop_notifications: bool, wildcard_mentions_notify: bool, enable_followed_topic_wildcard_mentions_notify: bool, desktop_icon_count_display: int, realm_name_in_email_notifications_policy: int, automatically_follow_topics_policy: int, automatically_unmute_topics_in_muted_streams_policy: int, automatically_follow_topics_where_mentioned: bool, resolved_topic_notice_auto_read_policy: string, presence_enabled: bool, enter_sends: bool, enable_drafts_synchronization: bool, email_notifications_batching_period_seconds: int, available_notification_sounds: list<string>, emojiset_choices: list<record>, send_private_typing_notifications: bool, send_stream_typing_notifications: bool, send_read_receipts: bool, allow_private_data_export: bool, email_address_visibility: int, web_navigate_to_sent_message: bool>, realm_users: table<user_id: any, delivery_email: any, email: any, full_name: any, date_joined: any, is_active: any, is_owner: any, is_admin: any, is_guest: any, is_bot: any, bot_type: any, bot_owner_id: any, role: any, timezone: any, avatar_url: any, avatar_version: any, is_imported_stub: any, is_deleted: any, profile_data: record>, realm_non_active_users: table<user_id: any, delivery_email: any, email: any, full_name: any, date_joined: any, is_active: any, is_owner: any, is_admin: any, is_guest: any, is_bot: any, bot_type: any, bot_owner_id: any, role: any, timezone: any, avatar_url: any, avatar_version: any, is_imported_stub: any, is_deleted: any, profile_data: record>, avatar_source: string, avatar_url_medium: string, avatar_url: string, can_create_streams: bool, can_create_public_streams: bool, can_create_private_streams: bool, can_create_web_public_streams: bool, can_subscribe_other_users: bool, can_invite_others_to_realm: bool, is_admin: bool, is_owner: bool, is_moderator: bool, is_guest: bool, user_id: int, email: string, delivery_email: string, full_name: string, cross_realm_bots: table<user_id: any, delivery_email: any, email: any, full_name: any, date_joined: any, is_active: any, is_owner: any, is_admin: any, is_guest: any, is_bot: any, bot_type: any, bot_owner_id: any, role: any, timezone: any, avatar_url: any, avatar_version: any, is_imported_stub: any, is_deleted: bool, is_system_bot: bool>, server_report_message_types: table<key: string, name: string>, server_supported_permission_settings: record<realm: record, stream: record, group: record>, max_bulk_new_subscription_messages: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/register")
  let body = {apply_markdown: $apply_markdown, client_gravatar: $client_gravatar, include_subscribers: $include_subscribers, slim_presence: $slim_presence, presence_history_limit_days: $presence_history_limit_days, event_types: $event_types, all_public_streams: $all_public_streams, client_capabilities: $client_capabilities, fetch_event_types: $fetch_event_types, narrow: $narrow, idle_queue_timeout: $idle_queue_timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get server settings
#
# GET /server_settings
# operationId: get-server-settings
export def "server-settings get-server-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, authentication_methods: record<password: bool, dev: bool, email: bool, ldap: bool, remoteuser: bool, github: bool, azuread: bool, gitlab: bool, apple: bool, google: bool, saml: bool, openid_connect: bool, discord: bool>, external_authentication_methods: table<name: string, display_name: string, display_icon: string, login_url: string, signup_url: string>, zulip_feature_level: int, zulip_version: string, zulip_merge_base: string, push_notifications_enabled: bool, is_incompatible: bool, email_auth_enabled: bool, require_email_format_usernames: bool, realm_uri: string, realm_url: string, realm_name: string, realm_icon: string, realm_description: string, realm_web_public_access_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/server_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update settings
#
# PATCH /settings
# operationId: update-settings
# --target_users shape: {user_ids?: list, group_ids?: list, skip_if_already_edited?: bool}
export def "settings update-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target-users: record # An object specifying the collection of users whose settings should be modified, for modification of other users' settings by an organization administrator. When this parameter is absent, this API endpoint always modifies the current user's own settings.  **Changes**: New in Zulip 12.0 (feature level 444).  (e.g. {user_ids: [6, 8], group_ids: [24], skip_if_already_edited: false}) — shape: {user_ids?: list, group_ids?: list, skip_if_already_edited?: bool}
  --full-name: string # A new display name for the user.  (e.g. NewName)
  --email: string # Asks the server to initiate a confirmation sequence to change the user's email address to the indicated value. The user will need to demonstrate control of the new email address by clicking a confirmation link sent to that address.  (e.g. newname@example.com)
  --old-password: string # The user's old Zulip password (or LDAP password, if LDAP authentication is in use).  Required only when sending the `new_password` parameter.  (e.g. old12345)
  --new-password: string # The user's new Zulip password (or LDAP password, if LDAP authentication is in use).  The `old_password` parameter must be included in the request.  (e.g. new12345)
  --twenty-four-hour-time: oneof<nothing, bool> # Whether time should be [displayed in 24-hour notation](/help/change-the-time-format).  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. true)
  --web-mark-read-on-scroll-policy: int@web-mark-read-on-scroll-policy-completer # Whether or not to mark messages as read when the user scrolls through their feed.  - 1 - Always - 2 - Only in conversation views - 3 - Never  **Changes**: New in Zulip 7.0 (feature level 175). Previously, there was no way for the user to configure this behavior on the web, and the Zulip web and desktop apps behaved like the "Always" setting when marking messages as read.  (e.g. 1)
  --web-channel-default-view: int@web-channel-default-view-completer-1 # Web/desktop app setting controlling the default navigation behavior when clicking on a channel link.  - 1 - Top topic in the channel - 2 - Channel feed - 3 - List of topics - 4 - Top unread topic in channel  **Changes**: The "Top unread topic in channel" is new in Zulip 11.0 (feature level 401).  The "List of topics" option is new in Zulip 11.0 (feature level 383).  New in Zulip 9.0 (feature level 269). Previously, this was not configurable, and every user had the "Channel feed" behavior.  (e.g. 1)
  --starred-message-counts: oneof<nothing, bool> # Whether clients should display the [number of starred messages](/help/star-a-message#display-the-number-of-starred-messages).  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. true)
  --receives-typing-notifications: oneof<nothing, bool> # Whether the user is configured to receive typing notifications from other users. The server will only deliver typing notifications events to users who for whom this is enabled.  By default, this is set to true, enabling user to receive typing notifications from other users.  **Changes**: New in Zulip 9.0 (feature level 253). Previously, there were only options to disable sending typing notifications.  (e.g. true)
  --web-suggest-update-timezone: oneof<nothing, bool> # Whether the user should be shown an alert, offering to update their [profile time zone](/help/change-your-timezone), when the time displayed for the profile time zone differs from the current time displayed by the time zone configured on their device.  **Changes**: New in Zulip 10.0 (feature level 329).  (e.g. true)
  --fluid-layout-width: oneof<nothing, bool> # Whether to use the [maximum available screen width](/help/enable-full-width-display) for the web app's center panel (message feed, recent conversations) on wide screens.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. true)
  --high-contrast-mode: oneof<nothing, bool> # This setting is reserved for use to control variations in Zulip's design to help visually impaired users.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. true)
  --web-font-size-px: int # User-configured primary `font-size` for the web application, in pixels.  **Changes**: New in Zulip 9.0 (feature level 245). Previously, font size was only adjustable via browser zoom. Note that this setting was not fully implemented at this feature level.  (e.g. 14)
  --web-line-height-percent: int # User-configured primary `line-height` for the web application, in percent, so a value of 120 represents a `line-height` of 1.2.  **Changes**: New in Zulip 9.0 (feature level 245). Previously, line height was not user-configurable. Note that this setting was not fully implemented at this feature level.  (e.g. 122)
  --color-scheme: int@color-scheme-completer # Controls which [color theme](/help/dark-theme) to use.  - 1 - Automatic - 2 - Dark theme - 3 - Light theme  Automatic detection is implementing using the standard `prefers-color-scheme` media query.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. 1)
  --enable-drafts-synchronization: oneof<nothing, bool> # A boolean parameter to control whether synchronizing drafts is enabled for the user. When synchronization is disabled, all drafts stored in the server will be automatically deleted from the server.  This does not do anything (like sending events) to delete local copies of drafts stored in clients.  **Changes**: New in Zulip 5.0 (feature level 87).  (e.g. true)
  --translate-emoticons: oneof<nothing, bool> # Whether to [translate emoticons to emoji](/help/configure-emoticon-translations) in messages the user sends.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. true)
  --display-emoji-reaction-users: oneof<nothing, bool> # Whether to display the names of reacting users on a message.  When enabled, clients should display the names of reacting users, rather than a count, for messages with few total reactions. The ideal cutoff may depend on the space available for displaying reactions; the official web application displays names when 3 or fewer total reactions are present with this setting enabled.  **Changes**: New in Zulip 6.0 (feature level 125).  (e.g. false)
  --default-language: string # What [default language](/help/change-your-language) to use for the account.  This controls both the Zulip UI as well as email notifications sent to the user.  The value needs to be a standard language code that the Zulip server has translation data for; for example, `"en"` for English or `"de"` for German.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  Unnecessary JSON-encoding of this parameter was removed in Zulip 4.0 (feature level 63).  (e.g. en)
  --web-home-view: string # The [home view](/help/configure-home-view) used when opening a new Zulip web app window or hitting the `Esc` keyboard shortcut repeatedly.  - "recent" - Recent conversations view - "inbox" - Inbox view - "all_messages" - Combined feed view  **Changes**: Before Zulip 12.0 (feature level 454), the Recent view had `"recent_topics"` as its string encoding.  New in Zulip 8.0 (feature level 219). Previously, this was called `default_view`, which was new in Zulip 4.0 (feature level 42).  Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  Unnecessary JSON-encoding of this parameter was removed in Zulip 4.0 (feature level 64).  (e.g. all_messages)
  --web-escape-navigates-to-home-view: oneof<nothing, bool> # Whether the escape key navigates to the [configured home view](/help/configure-home-view).  **Changes**: New in Zulip 8.0 (feature level 219). Previously, this was called `escape_navigates_to_default_view`, which was new in Zulip 5.0 (feature level 107).  (e.g. true)
  --left-side-userlist: oneof<nothing, bool> # Whether the users list on left sidebar in narrow windows.  This feature is not heavily used and is likely to be reworked.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. true)
  --emojiset: string # The user's configured [emoji set](/help/emoji-and-emoticons#use-emoticons), used to display emoji to the user everywhere they appear in the UI.  - "google" - Google modern - "twitter" - Twitter - "text" - Plain text  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  Unnecessary JSON-encoding of this parameter was removed in Zulip 4.0 (feature level 64).  (e.g. google)
  --demote-inactive-streams: int@demote-inactive-streams-completer # Whether to [hide inactive channels](/help/manage-inactive-channels) in the left sidebar.  - 1 - Automatic - 2 - Always - 3 - Never  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  (e.g. 1)
  --user-list-style: int@user-list-style-completer # The style selected by the user for the right sidebar user list.  - 1 - Compact - 2 - With status - 3 - With avatar and status  **Changes**: New in Zulip 6.0 (feature level 141).  (e.g. 1)
  --web-animate-image-previews: string@web-animate-image-previews-completer # Controls how animated images should be played in the message feed in the web/desktop application.  - "always" - Always play the animated images in the message feed. - "on_hover" - Play the animated images on hover over them in the message feed. - "never" - Never play animated images in the message feed.  **Changes**: New in Zulip 9.0 (feature level 275).  (e.g. on_hover)
  --web-stream-unreads-count-display-policy: int@web-stream-unreads-count-display-policy-completer # Configuration for which channels should be displayed with a numeric unread count in the left sidebar. Channels that do not have an unread count will have a simple dot indicator for whether there are any unread messages.  - 1 - All channels - 2 - Unmuted channels and topics - 3 - No channels  **Changes**: New in Zulip 8.0 (feature level 210).  (e.g. 2)
  --hide-ai-features: oneof<nothing, bool> # Controls whether user wants AI features like topic summarization to be hidden in all Zulip clients.  **Changes**: New in Zulip 10.0 (feature level 350).
  --web-inbox-show-channel-folders: oneof<nothing, bool> # Determines whether [channel folders](/help/channel-folders) are used to organize how conversations with unread messages are displayed in the web/desktop application's Inbox view.  **Changes**: New in Zulip 12.0 (feature level 431).
  --web-left-sidebar-show-channel-folders: oneof<nothing, bool> # Determines whether [channel folders](/help/channel-folders) are used to organize how channels are displayed in the web/desktop application's left sidebar.  **Changes**: New in Zulip 11.0 (feature level 411).  (e.g. true)
  --web-left-sidebar-unreads-count-summary: oneof<nothing, bool> # Determines whether the web/desktop application's left sidebar displays the unread message count summary.  **Changes**: New in Zulip 11.0 (feature level 398).  (e.g. true)
  --timezone: string # The IANA identifier of the user's [profile time zone](/help/change-your-timezone), which is used primarily to display the user's local time to other users.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/display` endpoint.  Unnecessary JSON-encoding of this parameter was removed in Zulip 4.0 (feature level 64).  (e.g. Asia/Kolkata)
  --enable-stream-desktop-notifications: oneof<nothing, bool> # Enable visual desktop notifications for channel messages.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-stream-email-notifications: oneof<nothing, bool> # Enable email notifications for channel messages.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-stream-push-notifications: oneof<nothing, bool> # Enable mobile notifications for channel messages.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-stream-audible-notifications: oneof<nothing, bool> # Enable audible desktop notifications for channel messages.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --notification-sound: string # Notification sound name.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  Unnecessary JSON-encoding of this parameter was removed in Zulip 4.0 (feature level 63).  (e.g. ding)
  --enable-desktop-notifications: oneof<nothing, bool> # Enable visual desktop notifications for direct messages and @-mentions.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-sounds: oneof<nothing, bool> # Enable audible desktop notifications for direct messages and @-mentions.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --email-notifications-batching-period-seconds: int # The duration (in seconds) for which the server should wait to batch email notifications before sending them.  **Changes**: New in Zulip 5.0 (feature level 82)  (e.g. 120)
  --enable-offline-email-notifications: oneof<nothing, bool> # Enable email notifications for direct messages and @-mentions received when the user is offline.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-offline-push-notifications: oneof<nothing, bool> # Enable mobile notification for direct messages and @-mentions received when the user is offline.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-online-push-notifications: oneof<nothing, bool> # Enable mobile notification for direct messages and @-mentions received when the user is online.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-followed-topic-desktop-notifications: oneof<nothing, bool> # Enable visual desktop notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. true)
  --enable-followed-topic-email-notifications: oneof<nothing, bool> # Enable email notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. true)
  --enable-followed-topic-push-notifications: oneof<nothing, bool> # Enable push notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. false)
  --enable-followed-topic-audible-notifications: oneof<nothing, bool> # Enable audible desktop notifications for messages sent to followed topics.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. false)
  --enable-digest-emails: oneof<nothing, bool> # Enable digest emails when the user is away.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-marketing-emails: oneof<nothing, bool> # Enable marketing emails. Has no function outside Zulip Cloud.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-login-emails: oneof<nothing, bool> # Enable email notifications for new logins to account.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --message-content-in-email-notifications: oneof<nothing, bool> # Include the message's content in email notifications for new messages.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --pm-content-in-desktop-notifications: oneof<nothing, bool> # Include content of direct messages in desktop notifications.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --wildcard-mentions-notify: oneof<nothing, bool> # Whether wildcard mentions (E.g. @**all**) should send notifications like a personal mention.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enable-followed-topic-wildcard-mentions-notify: oneof<nothing, bool> # Whether wildcard mentions (e.g., @**all**) in messages sent to followed topics should send notifications like a personal mention.  **Changes**: New in Zulip 8.0 (feature level 189).  (e.g. true)
  --desktop-icon-count-display: int@desktop-icon-count-display-completer # Unread count badge (appears in desktop sidebar and browser tab)  - 1 - All unread messages - 2 - DMs, mentions, and followed topics - 3 - DMs and mentions - 4 - None  **Changes**: In Zulip 8.0 (feature level 227), added `DMs, mentions, and followed topics` option, renumbering the options to insert it in order.  Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. 1)
  --realm-name-in-email-notifications-policy: int@realm-name-in-email-notifications-policy-completer # Whether to [include organization name in subject of message notification emails](/help/email-notifications#include-organization-name-in-subject-line).  - 1 - Automatic - 2 - Always - 3 - Never  **Changes**: New in Zulip 7.0 (feature level 168), replacing the previous `realm_name_in_notifications` boolean; `true` corresponded to `Always`, and `false` to `Never`.  Before Zulip 5.0 (feature level 80), the previous `realm_name_in_notifications` setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. 1)
  --automatically-follow-topics-policy: int@automatically-follow-topics-policy-completer # Which [topics to follow automatically](/help/mute-a-topic).  - 1 - Topics the user participates in - 2 - Topics the user sends a message to - 3 - Topics the user starts - 4 - Never  **Changes**: New in Zulip 8.0 (feature level 214).  (e.g. 1)
  --automatically-unmute-topics-in-muted-streams-policy: int@automatically-unmute-topics-in-muted-streams-policy-completer # Which [topics to unmute automatically in muted channels](/help/mute-a-topic).  - 1 - Topics the user participates in - 2 - Topics the user sends a message to - 3 - Topics the user starts - 4 - Never  **Changes**: New in Zulip 8.0 (feature level 214).  (e.g. 1)
  --automatically-follow-topics-where-mentioned: oneof<nothing, bool> # Whether the server will automatically mark the user as following topics where the user is mentioned.  **Changes**: New in Zulip 8.0 (feature level 235).  (e.g. true)
  --resolved-topic-notice-auto-read-policy: string@resolved-topic-notice-auto-read-policy-completer # Controls whether the resolved-topic notices are marked as read.  - "always" - Always mark resolved-topic notices as read. - "except_followed" - Mark resolved-topic notices as read in topics not followed by the user. - "never" - Never mark resolved-topic notices as read.  **Changes**: New in Zulip 11.0 (feature level 385).  (e.g. except_followed)
  --presence-enabled: oneof<nothing, bool> # Display the presence status to other users when online.  **Changes**: Before Zulip 5.0 (feature level 80), this setting was managed by the `PATCH /settings/notifications` endpoint.  (e.g. true)
  --enter-sends: oneof<nothing, bool> # Whether pressing Enter in the compose box sends a message (or saves a message edit).  **Changes**: Before Zulip 5.0 (feature level 81), this setting was managed by the `POST /users/me/enter-sends` endpoint, with the same parameter format.  (e.g. true)
  --send-private-typing-notifications: oneof<nothing, bool> # Whether [typing notifications](/help/typing-notifications) be sent when composing direct messages.  **Changes**: New in Zulip 5.0 (feature level 105).  (e.g. true)
  --send-stream-typing-notifications: oneof<nothing, bool> # Whether [typing notifications](/help/typing-notifications) be sent when composing channel messages.  **Changes**: New in Zulip 5.0 (feature level 105).  (e.g. true)
  --send-read-receipts: oneof<nothing, bool> # Whether other users are allowed to see whether you've read messages.  **Changes**: New in Zulip 5.0 (feature level 105).  (e.g. true)
  --allow-private-data-export: oneof<nothing, bool> # Whether organization administrators are allowed to export your private data.  **Changes**: New in Zulip 10.0 (feature level 293).  (e.g. true)
  --email-address-visibility: int@email-address-visibility-completer # The [policy][permission-level] this user has selected for [which other users][help-email-visibility] in this organization can see their real email address.  - 1 = Everyone - 2 = Members only - 3 = Administrators only - 4 = Nobody - 5 = Moderators only  **Changes**: New in Zulip 7.0 (feature level 163), replacing the realm-level setting.  [permission-level]: /api/roles-and-permissions#permission-levels [help-email-visibility]: /help/configure-email-visibility  (e.g. 1)
  --web-navigate-to-sent-message: oneof<nothing, bool> # Web/desktop app setting for whether the user's view should automatically go to the conversation where they sent a message.  **Changes**: New in Zulip 9.0 (feature level 268). Previously, this behavior was not configurable.  (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let body = {target_users: $target_users, full_name: $full_name, email: $email, old_password: $old_password, new_password: $new_password, twenty_four_hour_time: $twenty_four_hour_time, web_mark_read_on_scroll_policy: $web_mark_read_on_scroll_policy, web_channel_default_view: $web_channel_default_view, starred_message_counts: $starred_message_counts, receives_typing_notifications: $receives_typing_notifications, web_suggest_update_timezone: $web_suggest_update_timezone, fluid_layout_width: $fluid_layout_width, high_contrast_mode: $high_contrast_mode, web_font_size_px: $web_font_size_px, web_line_height_percent: $web_line_height_percent, color_scheme: $color_scheme, enable_drafts_synchronization: $enable_drafts_synchronization, translate_emoticons: $translate_emoticons, display_emoji_reaction_users: $display_emoji_reaction_users, default_language: $default_language, web_home_view: $web_home_view, web_escape_navigates_to_home_view: $web_escape_navigates_to_home_view, left_side_userlist: $left_side_userlist, emojiset: $emojiset, demote_inactive_streams: $demote_inactive_streams, user_list_style: $user_list_style, web_animate_image_previews: $web_animate_image_previews, web_stream_unreads_count_display_policy: $web_stream_unreads_count_display_policy, hide_ai_features: $hide_ai_features, web_inbox_show_channel_folders: $web_inbox_show_channel_folders, web_left_sidebar_show_channel_folders: $web_left_sidebar_show_channel_folders, web_left_sidebar_unreads_count_summary: $web_left_sidebar_unreads_count_summary, timezone: $timezone, enable_stream_desktop_notifications: $enable_stream_desktop_notifications, enable_stream_email_notifications: $enable_stream_email_notifications, enable_stream_push_notifications: $enable_stream_push_notifications, enable_stream_audible_notifications: $enable_stream_audible_notifications, notification_sound: $notification_sound, enable_desktop_notifications: $enable_desktop_notifications, enable_sounds: $enable_sounds, email_notifications_batching_period_seconds: $email_notifications_batching_period_seconds, enable_offline_email_notifications: $enable_offline_email_notifications, enable_offline_push_notifications: $enable_offline_push_notifications, enable_online_push_notifications: $enable_online_push_notifications, enable_followed_topic_desktop_notifications: $enable_followed_topic_desktop_notifications, enable_followed_topic_email_notifications: $enable_followed_topic_email_notifications, enable_followed_topic_push_notifications: $enable_followed_topic_push_notifications, enable_followed_topic_audible_notifications: $enable_followed_topic_audible_notifications, enable_digest_emails: $enable_digest_emails, enable_marketing_emails: $enable_marketing_emails, enable_login_emails: $enable_login_emails, message_content_in_email_notifications: $message_content_in_email_notifications, pm_content_in_desktop_notifications: $pm_content_in_desktop_notifications, wildcard_mentions_notify: $wildcard_mentions_notify, enable_followed_topic_wildcard_mentions_notify: $enable_followed_topic_wildcard_mentions_notify, desktop_icon_count_display: $desktop_icon_count_display, realm_name_in_email_notifications_policy: $realm_name_in_email_notifications_policy, automatically_follow_topics_policy: $automatically_follow_topics_policy, automatically_unmute_topics_in_muted_streams_policy: $automatically_unmute_topics_in_muted_streams_policy, automatically_follow_topics_where_mentioned: $automatically_follow_topics_where_mentioned, resolved_topic_notice_auto_read_policy: $resolved_topic_notice_auto_read_policy, presence_enabled: $presence_enabled, enter_sends: $enter_sends, send_private_typing_notifications: $send_private_typing_notifications, send_stream_typing_notifications: $send_stream_typing_notifications, send_read_receipts: $send_read_receipts, allow_private_data_export: $allow_private_data_export, email_address_visibility: $email_address_visibility, web_navigate_to_sent_message: $web_navigate_to_sent_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get channel subscribers
#
# GET /streams/{stream_id}/members
# operationId: get-subscribers
export def "streams-members get-subscribers" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, subscribers: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/streams/($stream_id)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all channels
#
# GET /streams
# operationId: get-streams
@deprecated --flag include-all-active
export def "streams get-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-public: oneof<nothing, bool> # Include all public channels.  (default: true, e.g. false)
  --include-web-public: oneof<nothing, bool> # Include all web-public channels.  (default: false, e.g. true)
  --include-subscribed: oneof<nothing, bool> # Include all channels that the user is subscribed to.  (default: true, e.g. false)
  --exclude-archived: oneof<nothing, bool> # Whether to exclude archived streams from the results.  **Changes**: New in Zulip 10.0 (feature level 315).  (default: true, e.g. true)
  --include-all-active: oneof<nothing, bool> # Deprecated parameter to include all channels. The user must have administrative privileges to use this parameter.  **Changes**: Deprecated in Zulip 10.0 (feature level 356). Clients interacting with newer servers should use the equivalent `include_all` parameter, which does not incorrectly hint that this parameter, and not `exclude_archived`, controls whether archived channels appear in the response.  (DEPRECATED, default: false, e.g. true)
  --include-all: oneof<nothing, bool> # Include all channels that the user has metadata access to.  For organization administrators, this will be all channels in the organization, since organization administrators implicitly have metadata access to all channels.  **Changes**: New in Zulip 10.0 (feature level 356). On older versions, use `include_all_active`, which this replaces.  (default: false, e.g. true)
  --include-default: oneof<nothing, bool> # Include all default channels for the user's realm.  (default: false, e.g. true)
  --include-owner-subscribed: oneof<nothing, bool> # If the user is a bot, include all channels that the bot's owner is subscribed to.  (default: false, e.g. true)
  --include-can-access-content: oneof<nothing, bool> # Include all the channels that the user has content access to.  **Changes**: New in Zulip 10.0 (feature level 356).  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, streams: table<stream_id: any, name: any, is_archived: any, description: any, date_created: any, creator_id: any, invite_only: any, rendered_description: any, is_web_public: any, stream_post_policy: any, message_retention_days: any, history_public_to_subscribers: any, topics_policy: any, first_message_id: any, folder_id: any, is_recently_active: any, is_announcement_only: any, can_add_subscribers_group: any, can_remove_subscribers_group: any, can_administer_channel_group: any, can_delete_any_message_group: any, can_delete_own_message_group: any, can_move_messages_out_of_channel_group: any, can_move_messages_within_channel_group: any, can_send_message_group: any, can_subscribe_group: any, can_resolve_topics_group: any, can_create_topic_group: any, subscriber_count: any, stream_weekly_traffic: int, is_default: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_public" $include_public "scalar") (serialize-qp "include_web_public" $include_web_public "scalar") (serialize-qp "include_subscribed" $include_subscribed "scalar") (serialize-qp "exclude_archived" $exclude_archived "scalar") (serialize-qp "include_all_active" $include_all_active "scalar") (serialize-qp "include_all" $include_all "scalar") (serialize-qp "include_default" $include_default "scalar") (serialize-qp "include_owner_subscribed" $include_owner_subscribed "scalar") (serialize-qp "include_can_access_content" $include_can_access_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a channel by ID
#
# GET /streams/{stream_id}
# operationId: get-stream-by-id
export def "streams get-stream-by-id" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, stream: record<stream_id: any, name: any, is_archived: any, description: any, date_created: any, creator_id: any, invite_only: any, rendered_description: any, is_web_public: any, stream_post_policy: any, message_retention_days: any, history_public_to_subscribers: any, topics_policy: any, first_message_id: any, folder_id: any, is_recently_active: any, is_announcement_only: any, can_add_subscribers_group: any, can_remove_subscribers_group: any, can_administer_channel_group: any, can_delete_any_message_group: any, can_delete_own_message_group: any, can_move_messages_out_of_channel_group: any, can_move_messages_within_channel_group: any, can_send_message_group: any, can_subscribe_group: any, can_resolve_topics_group: any, can_create_topic_group: any, subscriber_count: any, stream_weekly_traffic: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/streams/($stream_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a channel
#
# DELETE /streams/{stream_id}
# operationId: archive-stream
export def "streams archive-stream" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/streams/($stream_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a channel
#
# PATCH /streams/{stream_id}
# operationId: update-stream
export def "streams update-stream" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The new [description](/help/change-the-channel-description) for the channel, in [Zulip-flavored Markdown](/help/format-your-message-using-markdown) format.  Clients should use the `max_stream_description_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel description length.  **Changes**: Removed unnecessary JSON-encoding of this parameter in Zulip 4.0 (feature level 64).  (e.g. Discuss Italian history and travel destinations.)
  --new-name: string # The new name for the channel.  Clients should use the `max_stream_name_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel name length.  **Changes**: Removed unnecessary JSON-encoding of this parameter in Zulip 4.0 (feature level 64).  (e.g. Italy)
  --is-private: oneof<nothing, bool> # Change whether the channel is a private channel.  (e.g. true)
  --is-web-public: oneof<nothing, bool> # Change whether the channel is a web-public channel.  Note that creating web-public channels requires the `WEB_PUBLIC_STREAMS_ENABLED` [server setting][server-settings] to be enabled on the Zulip server in question, the organization to have enabled the `enable_spectator_access` realm setting, and the current use to have permission under the organization's `can_create_web_public_channel_group` realm setting.  [server-settings]: https://zulip.readthedocs.io/en/stable/production/settings.html  **Changes**: New in Zulip 5.0 (feature level 98).  (e.g. true)
  --history-public-to-subscribers: oneof<nothing, bool> # Whether the channel's message history should be available to newly subscribed members, or users can only access messages they actually received while subscribed to the channel.  Corresponds to the shared history option for [private channels](/help/channel-permissions#private-channels).  It's an error for this parameter to be false for a public or web-public channel and when is_private is false.  This can only be `false` if `can_create_topic_group` for the channel is the `role:everyone` [system group][system-groups].  **Changes**: Before Zulip 6.0 (feature level 136), `history_public_to_subscribers` was silently ignored unless the request also contained either `is_private` or `is_web_public`.  [system-groups]: /api/group-setting-values#system-groups  (e.g. false)
  --is-default-stream: oneof<nothing, bool> # Add or remove the channel as a [default channel][default-channel] for new users joining the organization.  [default-channel]: /help/set-default-channels-for-new-users  **Changes**: New in Zulip 8.0 (feature level 200). Previously, default channel status could only be changed using the [dedicated API endpoint](/api/add-default-stream).  (e.g. false)
  --message-retention-days: any # Number of days that messages sent to this channel will be stored before being automatically deleted by the [message retention policy](/help/message-retention-policy). Two special string format values are supported:  - `"realm_default"`: Return to the organization-level setting. - `"unlimited"`: Retain messages forever.  **Changes**: Prior to Zulip 5.0 (feature level 91), retaining messages forever was encoded using `"forever"` instead of `"unlimited"`.  New in Zulip 3.0 (feature level 17).  (e.g. 20)
  --is-archived: oneof<nothing, bool> # A boolean indicating whether the channel is [archived](/help/archive-a-channel) or unarchived. Currently only allows unarchiving previously archived channels.  **Changes**: New in Zulip 11.0 (feature level 388).  (e.g. true)
  --folder-id: int # ID of the new [channel folder](/help/channel-folders) to which the channel should belong.  A `null` value indicates the user wants to remove the channel from its current channel folder.  **Changes**: New in Zulip 11.0 (feature level 389).  (nullable, e.g. 1)
  --topics-policy: string@topics-policy-completer # Whether [named topics](/help/introduction-to-topics) and the empty topic (i.e., ["general chat" topic](/help/general-chat-topic)) are enabled in this channel.  - `"inherit"`: Messages can be sent to named topics in this channel,   and the [organization-level `realm_topics_policy`][realm-topics-policy]   is used for whether messages can be sent to the empty topic in this   channel. - `"allow_empty_topic"`: Messages can be sent to both named topics and   the empty topic in this channel. - `"disable_empty_topic"`: Messages can be sent to named topics in this   channel, but the empty topic is disabled. - `"empty_topic_only"`: Messages can be sent to the empty topic in this   channel, but named topics are disabled. See ["general chat"   channels](/help/general-chat-channels).  The `"empty_topic_only"` policy can only be set if all existing messages in the channel are already in the empty topic.  When creating a new channel, if the `topics_policy` is not specified, the `"inherit"` option will be set.  **Changes**: In Zulip 11.0 (feature level 404), the `"empty_topic_only"` option was added.  New in Zulip 11.0 (feature level 392).  [realm-topics-policy]: /help/require-topics#set-the-default-general-chat-topic-configuration  (e.g. inherit)
  --can-add-subscribers-group: any
  --can-remove-subscribers-group: any
  --can-administer-channel-group: any
  --can-delete-any-message-group: any
  --can-delete-own-message-group: any
  --can-move-messages-out-of-channel-group: any
  --can-move-messages-within-channel-group: any
  --can-send-message-group: any
  --can-subscribe-group: any
  --can-resolve-topics-group: any
  --can-create-topic-group: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/streams/($stream_id)")
  let body = {description: $description, new_name: $new_name, is_private: $is_private, is_web_public: $is_web_public, history_public_to_subscribers: $history_public_to_subscribers, is_default_stream: $is_default_stream, message_retention_days: $message_retention_days, is_archived: $is_archived, folder_id: $folder_id, topics_policy: $topics_policy, can_add_subscribers_group: $can_add_subscribers_group, can_remove_subscribers_group: $can_remove_subscribers_group, can_administer_channel_group: $can_administer_channel_group, can_delete_any_message_group: $can_delete_any_message_group, can_delete_own_message_group: $can_delete_own_message_group, can_move_messages_out_of_channel_group: $can_move_messages_out_of_channel_group, can_move_messages_within_channel_group: $can_move_messages_within_channel_group, can_send_message_group: $can_send_message_group, can_subscribe_group: $can_subscribe_group, can_resolve_topics_group: $can_resolve_topics_group, can_create_topic_group: $can_create_topic_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get channel's email address
#
# GET /streams/{stream_id}/email_address
# operationId: get-stream-email-address
export def "streams-email-address get-stream-email-address" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sender-id: int # The ID of a user or bot which should appear as the sender when messages are sent to the channel using the returned channel email address.  `sender_id` can be:  - ID of the current user. - ID of the Email gateway bot. (Default value) - ID of a bot owned by the current user.  **Changes**: New in Zulip 10.0 (feature level 335).  Previously, the sender was always Email gateway bot.  (e.g. 1)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sender_id" $sender_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/streams/($stream_id)/email_address" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a topic
#
# POST /streams/{stream_id}/delete_topic
# operationId: delete-topic
export def "streams-delete-topic delete-topic" [
  stream_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  topic_name: string # The name of the topic to delete.  Note: When the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  **Changes**: Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  (e.g. new coffee machine)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, complete: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/streams/($stream_id)/delete_topic")
  let body = {topic_name: $topic_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set "typing" status
#
# POST /typing
# operationId: set-typing-status
export def "typing set-typing-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-1 # Type of the message being composed.  **Changes**: In Zulip 9.0 (feature level 248), `"channel"` was added as an additional value for this parameter to indicate a channel message is being composed.  In Zulip 8.0 (feature level 215), stopped supporting `"private"` as a valid value for this parameter.  In Zulip 7.0 (feature level 174), `"direct"` was added as the preferred way to indicate a direct message is being composed, becoming the default value for this parameter and deprecating the original `"private"`.  New in Zulip 4.0 (feature level 58). Previously, typing notifications were only for direct messages.  (default: direct, e.g. direct)
  op: string@op-completer-1 # Whether the user has started (`"start"`) or stopped (`"stop"`) typing.  (e.g. start)
  --body-to: list # User IDs of the recipients of the message being typed. Required for the `"direct"` type. Ignored in the case of `"stream"` or `"channel"` type.  Clients should send a JSON-encoded list of user IDs, even if there is only one recipient.  **Changes**: In Zulip 8.0 (feature level 215), stopped using this parameter for the `"stream"` type. Previously, in the case of the `"stream"` type, it accepted a single-element list containing the ID of the channel. A new parameter, `stream_id`, is now used for this. Note that the `"channel"` type did not exist at this feature level.  Support for typing notifications for channel' messages is new in Zulip 4.0 (feature level 58). Previously, typing notifications were only for direct messages.  Before Zulip 2.0.0, this parameter accepted only a JSON-encoded list of email addresses. Support for the email address-based format was removed in Zulip 3.0 (feature level 11).  (e.g. [9, 10])
  --stream-id: int # ID of the channel in which the message is being typed. Required for the `"stream"` or `"channel"` type. Ignored in the case of `"direct"` type.  **Changes**: New in Zulip 8.0 (feature level 215). Previously, a single-element list containing the ID of the channel was passed in `to` parameter.  (e.g. 7)
  --topic: string # Topic to which message is being typed. Required for the `"stream"` or `"channel"` type. Ignored in the case of `"direct"` type.  Note: When `"(no topic)"` or the value of `realm_empty_topic_display_name` found in the [POST /register](/api/register-queue) response is used for this parameter, it is interpreted as an empty string.  **Changes**: Before Zulip 10.0 (feature level 372), `"(no topic)"` was not interpreted as an empty string.  Before Zulip 10.0 (feature level 334), empty string was not a valid topic name for channel messages.  New in Zulip 4.0 (feature level 58). Previously, typing notifications were only for direct messages.  (e.g. typing notifications)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/typing")
  let body = {type: $type, op: $op, to: $body_to, stream_id: $stream_id, topic: $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set "typing" status for message editing
#
# POST /messages/{message_id}/typing
# operationId: set-typing-status-for-message-edit
export def "messages-typing set-typing-status-for-message-edit" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  op: string@op-completer-1 # Whether the user has started (`"start"`) or stopped (`"stop"`) editing.  (e.g. start)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($message_id)/typing")
  let body = {op: $op} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a channel
#
# POST /channels/create
# operationId: create-channel
export def "channels-create create-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the new channel.  Clients should use the `max_stream_name_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel name length.  (e.g. music)
  --description: string # The [description](/help/change-the-channel-description) to use for the new channel being created, in text/markdown format.  Clients should use the `max_stream_description_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel description length.  (e.g. Channel for discussing all things music!)
  subscribers: list # A list of user IDs of the users to be subscribed to the new channel.  (e.g. [17, 12])
  --announce: oneof<nothing, bool> # This determines whether [notification bot](/help/configure-automated-notices) will send an announcement about the new channel's creation.  (default: false, e.g. true)
  --invite-only: oneof<nothing, bool> # This parameter and the ones that follow are used to request an initial configuration of the new channel.  This parameter determines whether the newly created channel will be a [private channel](/help/channel-permissions#private-channels).  (default: false, e.g. true)
  --is-web-public: oneof<nothing, bool> # This parameter determines whether the newly created channel will be a web-public channel.  Note that creating web-public channels requires the `WEB_PUBLIC_STREAMS_ENABLED` [server setting][server-settings] to be enabled on the Zulip server in question, the organization to have enabled the `enable_spectator_access` realm setting, and the current user to have permission under the organization's `can_create_web_public_channel_group` realm setting.  [server-settings]: https://zulip.readthedocs.io/en/stable/production/settings.html  (default: false, e.g. true)
  --is-default-stream: oneof<nothing, bool> # This parameter determines whether the newly created channel will be added as a [default channel][default-channels] for new users joining the organization.  [default-channels]: /help/set-default-channels-for-new-users  (default: false, e.g. true)
  --folder-id: int # This parameter adds the newly created channel to the specified [channel folder](/help/channel-folders).  **Changes**: New in Zulip 11.0 (feature level 389).  (e.g. 1)
  --topics-policy: string@topics-policy-completer # Whether [named topics](/help/introduction-to-topics) and the empty topic (i.e., ["general chat" topic](/help/general-chat-topic)) are enabled in this channel.  - `"inherit"`: Messages can be sent to named topics in this channel,   and the [organization-level `realm_topics_policy`][realm-topics-policy]   is used for whether messages can be sent to the empty topic in this   channel. - `"allow_empty_topic"`: Messages can be sent to both named topics and   the empty topic in this channel. - `"disable_empty_topic"`: Messages can be sent to named topics in this   channel, but the empty topic is disabled. - `"empty_topic_only"`: Messages can be sent to the empty topic in this   channel, but named topics are disabled. See ["general chat"   channels](/help/general-chat-channels).  The `"empty_topic_only"` policy can only be set if all existing messages in the channel are already in the empty topic.  When creating a new channel, if the `topics_policy` is not specified, the `"inherit"` option will be set.  **Changes**: In Zulip 11.0 (feature level 404), the `"empty_topic_only"` option was added.  New in Zulip 11.0 (feature level 392).  [realm-topics-policy]: /help/require-topics#set-the-default-general-chat-topic-configuration  (e.g. inherit)
  --history-public-to-subscribers: oneof<nothing, bool> # Whether the channel's message history should be available to newly subscribed members, or users can only access messages they actually received while subscribed to the channel.  Corresponds to the shared history option for [private channels](/help/channel-permissions#private-channels).  (e.g. false)
  --message-retention-days: any # Number of days that messages sent to this channel will be stored before being automatically deleted by the [message retention policy](/help/message-retention-policy). Two special string format values are supported:  - `"realm_default"`: Return to the organization-level setting. - `"unlimited"`: Retain messages forever.  **Changes**: Prior to Zulip 5.0 (feature level 91), retaining messages forever was encoded using `"forever"` instead of `"unlimited"`.  New in Zulip 3.0 (feature level 17).  (e.g. 20)
  --can-add-subscribers-group: any
  --can-create-topic-group: any
  --can-delete-any-message-group: any
  --can-delete-own-message-group: any
  --can-remove-subscribers-group: any
  --can-administer-channel-group: any
  --can-move-messages-out-of-channel-group: any
  --can-move-messages-within-channel-group: any
  --can-send-message-group: any
  --can-subscribe-group: any
  --can-resolve-topics-group: any
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/create")
  let body = {name: $name, description: $description, subscribers: $subscribers, announce: $announce, invite_only: $invite_only, is_web_public: $is_web_public, is_default_stream: $is_default_stream, folder_id: $folder_id, topics_policy: $topics_policy, history_public_to_subscribers: $history_public_to_subscribers, message_retention_days: $message_retention_days, can_add_subscribers_group: $can_add_subscribers_group, can_create_topic_group: $can_create_topic_group, can_delete_any_message_group: $can_delete_any_message_group, can_delete_own_message_group: $can_delete_own_message_group, can_remove_subscribers_group: $can_remove_subscribers_group, can_administer_channel_group: $can_administer_channel_group, can_move_messages_out_of_channel_group: $can_move_messages_out_of_channel_group, can_move_messages_within_channel_group: $can_move_messages_within_channel_group, can_send_message_group: $can_send_message_group, can_subscribe_group: $can_subscribe_group, can_resolve_topics_group: $can_resolve_topics_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a user group
#
# POST /user_groups/create
# operationId: create-user-group
export def "user-groups-create create-user-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the user group.  (e.g. marketing)
  description: string # The description of the user group.  (e.g. The marketing team.)
  members: list # An array containing the user IDs of the initial members for the new user group.  (e.g. [1, 2, 3, 4])
  --subgroups: list # An array containing the IDs of the initial subgroups for the new user group.  User can add subgroups to the new group irrespective of other permissions for the new group.  **Changes**: New in Zulip 10.0 (feature level 311).  (e.g. [11])
  --can-add-members-group: any # e.g. 11
  --can-join-group: any # e.g. 11
  --can-leave-group: any # e.g. 15
  --can-manage-group: any # e.g. 11
  --can-mention-group: any # e.g. 11
  --can-remove-members-group: any # e.g. 11
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, group_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_groups/create")
  let body = {name: $name, description: $description, members: $members, subgroups: $subgroups, can_add_members_group: $can_add_members_group, can_join_group: $can_join_group, can_leave_group: $can_leave_group, can_manage_group: $can_manage_group, can_mention_group: $can_mention_group, can_remove_members_group: $can_remove_members_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update user group members
#
# POST /user_groups/{user_group_id}/members
# operationId: update-user-group-members
export def "user-groups-members update-user-group-members" [
  user_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: list # The list of user IDs to be removed from the user group.  (e.g. [10])
  --add: list # The list of user IDs to be added to the user group.  (e.g. [12, 13])
  --delete-subgroups: list # The list of user group IDs to be removed from the user group.  **Changes**: New in Zulip 10.0 (feature level 311).  (e.g. [9])
  --add-subgroups: list # The list of user group IDs to be added to the user group.  **Changes**: New in Zulip 10.0 (feature level 311).  (e.g. [9])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_groups/($user_group_id)/members")
  let body = {delete: $delete, add: $add, delete_subgroups: $delete_subgroups, add_subgroups: $add_subgroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get user group members
#
# GET /user_groups/{user_group_id}/members
# operationId: get-user-group-members
export def "user-groups-members get-user-group-members" [
  user_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --direct-member-only: oneof<nothing, bool> # Whether to consider only the direct members of user group and not members of its subgroups. Default is `false`.  (e.g. false)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, members: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direct_member_only" $direct_member_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_groups/($user_group_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user group
#
# PATCH /user_groups/{user_group_id}
# operationId: update-user-group
export def "user-groups update-user-group" [
  user_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new name of the group.  **Changes**: Before Zulip 7.0 (feature level 165), this was a required field.  (e.g. marketing team)
  --description: string # The new description of the group.  **Changes**: Before Zulip 7.0 (feature level 165), this was a required field.  (e.g. The marketing team.)
  --can-add-members-group: any
  --can-join-group: any
  --can-leave-group: any
  --can-manage-group: any
  --can-mention-group: any
  --can-remove-members-group: any
  --deactivated: oneof<nothing, bool> # A deactivated user group can be reactivated by passing this parameter as `false`.  Passing `true` does nothing as user group is deactivated using [`POST /user_groups/{user_group_id}/deactivate`](deactivate-user-group) endpoint.  **Changes**: New in Zulip 11.0 (feature level 386).  (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_groups/($user_group_id)")
  let body = {name: $name, description: $description, can_add_members_group: $can_add_members_group, can_join_group: $can_join_group, can_leave_group: $can_leave_group, can_manage_group: $can_manage_group, can_mention_group: $can_mention_group, can_remove_members_group: $can_remove_members_group, deactivated: $deactivated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get user groups
#
# GET /user_groups
# operationId: get-user-groups
export def "user-groups get-user-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deactivated-groups: oneof<nothing, bool> # Whether to include deactivated user groups in the response.  **Changes**: In Zulip 10.0 (feature level 294), renamed `allow_deactivated` to `include_deactivated_groups`.  New in Zulip 10.0 (feature level 290). Previously, deactivated user groups did not exist and thus would never be included in the response.  (default: false, e.g. true)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, user_groups: table<description: string, id: int, date_created: int, creator_id: int, members: list, direct_subgroup_ids: list, name: string, is_system_group: bool, can_add_members_group: record, can_join_group: record, can_leave_group: record, can_manage_group: record, can_mention_group: record, can_remove_members_group: record, deactivated: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_groups")
  let body = {include_deactivated_groups: $include_deactivated_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update subgroups of a user group
#
# POST /user_groups/{user_group_id}/subgroups
# operationId: update-user-group-subgroups
export def "user-groups-subgroups update-user-group-subgroups" [
  user_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: list # The list of user group IDs to be removed from the user group.  (e.g. [10])
  --add: list # The list of user group IDs to be added to the user group.  (e.g. [10])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_groups/($user_group_id)/subgroups")
  let body = {delete: $delete, add: $add} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get subgroups of a user group
#
# GET /user_groups/{user_group_id}/subgroups
# operationId: get-user-group-subgroups
export def "user-groups-subgroups get-user-group-subgroups" [
  user_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --direct-subgroup-only: oneof<nothing, bool> # Whether to consider only direct subgroups of the user group or subgroups of subgroups also.  (default: false, e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, subgroups: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direct_subgroup_only" $direct_subgroup_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_groups/($user_group_id)/subgroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user group membership status
#
# GET /user_groups/{user_group_id}/members/{user_id}
# operationId: get-is-user-group-member
export def "user-groups-members get-is-user-group-member" [
  user_group_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --direct-member-only: oneof<nothing, bool> # Whether to consider only the direct members of user group and not members of its subgroups. Default is `false`.  (e.g. false)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, is_user_group_member: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direct_member_only" $direct_member_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_groups/($user_group_id)/members/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate a user group
#
# POST /user_groups/{user_group_id}/deactivate
# operationId: deactivate-user-group
export def "user-groups-deactivate deactivate-user-group" [
  user_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_groups/($user_group_id)/deactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a channel folder
#
# POST /channel_folders/create
# operationId: create-channel-folder
export def "channel-folders-create create-channel-folder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the channel folder.  Clients should use the `max_channel_folder_name_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel folder name length.  Value cannot be an empty string.  (e.g. marketing)
  --description: string # The description of the channel folder.  Clients should use the `max_channel_folder_description_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel folder description length.  Note that this parameter must be passed as part of the request, but can be an empty string if no description for the new channel folder is desired.  (e.g. Channels for marketing.)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, channel_folder_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channel_folders/create")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get channel folders
#
# GET /channel_folders
# operationId: get-channel-folders
export def "channel-folders get-channel-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-archived: oneof<nothing, bool> # Whether to include archived channel folders in the response.  (default: false, e.g. true)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, channel_folders: table<id: int, name: string, order: int, date_created: int, creator_id: int, description: string, rendered_description: string, is_archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channel_folders")
  let body = {include_archived: $include_archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Reorder channel folders
#
# PATCH /channel_folders
# operationId: patch-channel-folders
export def "channel-folders patch-channel-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  order: list # A list of channel folder IDs representing the new order.  This list must include the IDs of [all the organization's channel folders](/api/get-channel-folders), including archived folders.  (e.g. [2, 1])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channel_folders")
  let body = {order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update a channel folder
#
# PATCH /channel_folders/{channel_folder_id}
# operationId: update-channel-folder
export def "channel-folders update-channel-folder" [
  channel_folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new name of the channel folder.  Clients should use the `max_channel_folder_name_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel folder name length.  Value cannot be an empty string.  (e.g. backend)
  --description: string # The new description of the channel folder.  Clients should use the `max_channel_folder_description_length` returned by the [`POST /register`](/api/register-queue) endpoint to determine the maximum channel folder description length.  (e.g. Backend channels.)
  --is-archived: oneof<nothing, bool> # Whether to archive or unarchive the channel folder.  (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channel_folders/($channel_folder_id)")
  let body = {name: $name, description: $description, is_archived: $is_archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a bot's API key
#
# GET /bots/{bot_id}/api_key
# operationId: get-bot-api-key
export def "bots-api-key get-bot-api-key" [
  bot_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($bot_id)/api_key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerate a bot's API key
#
# POST /bots/{bot_id}/api_key/regenerate
# operationId: regenerate-bot-api-key
export def "bots-api-key-regenerate regenerate-bot-api-key" [
  bot_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($bot_id)/api_key/regenerate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (Ignored)
#
# POST /real-time
export def "real-time post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event-types: list # A JSON-encoded array indicating which types of events you're interested in. Values that you might find useful include:  - **message** (messages) - **subscription** (changes in your subscriptions) - **realm_user** (changes to users in the organization and   their properties, such as their name).  If you do not specify this parameter, you will receive all events, and have to filter out the events not relevant to your client in your client code. For most applications, one is only interested in messages, so one specifies: `"event_types": ["message"]`  Event types not supported by the server are ignored, in order to simplify the implementation of client apps that support multiple server versions.  (e.g. [message])
  --narrow: list # A JSON-encoded array of arrays of length 2 indicating the [narrow filter(s)](/api/construct-narrow) for which you'd like to receive events for.  For example, to receive events for direct messages (including group direct messages) received by the user, one can use `"narrow": [["is", "dm"]]`.  Unlike the API for [fetching messages](/api/get-messages), this narrow parameter is simply a filter on messages that the user receives through their channel subscriptions (or because they are a recipient of a direct message).  This means that a client that requests a `narrow` filter of `[["channel", "Denmark"]]` will receive events for new messages sent to that channel while the user is subscribed to that channel. The client will not receive any message events at all if the user is not subscribed to `"Denmark"`.  Newly created bot users are not usually subscribed to any channels, so bots using this API need to be [subscribed](/api/subscribe) to any channels whose messages you'd like them to process using this endpoint.  See the `all_public_streams` parameter for how to process all public channel messages in an organization.  **Changes**: See [changes section](/api/construct-narrow#changes) of search/narrow filter documentation.  (default: [], e.g. [[channel, Denmark]])
  --all-public-streams: oneof<nothing, bool> # Whether you would like to request message events from all public channels. Useful for workflow bots that you'd like to see all new messages sent to public channels. (You can also subscribe the user to private channels).  (default: false, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/real-time")
  let body = {event_types: $event_types, narrow: $narrow, all_public_streams: $all_public_streams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Error handling
#
# POST /rest-error-handling
# operationId: rest-error-handling
export def "rest-error-handling rest-error-handling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest-error-handling")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Outgoing webhooks
#
# POST /zulip-outgoing-webhook
# operationId: zulip-outgoing-webhooks
export def "zulip-outgoing-webhook zulip-outgoing-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<bot_email: string, bot_full_name: string, data: string, trigger: string, token: string, message: record<avatar_url: any, client: any, content: any, content_type: any, display_recipient: any, edit_history: any, id: any, is_me_message: any, last_edit_timestamp: any, last_moved_timestamp: any, reactions: any, recipient_id: any, sender_email: any, sender_full_name: any, sender_id: any, sender_realm_str: any, stream_id: any, subject: any, submessages: any, timestamp: any, topic_links: any, type: any, rendered_content: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/zulip-outgoing-webhook")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create BigBlueButton video call
#
# GET /calls/bigbluebutton/create
# operationId: create-big-blue-button-video-call
export def "calls-bigbluebutton-create create-big-blue-button-video-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meeting-name: string # Meeting name for the BigBlueButton video call.  (e.g. test_channel meeting)
  --voice-only: oneof<nothing, bool> # Configures whether the call is voice-only; if true, disables cameras for all users. Only the call creator/moderator can edit this configuration.  **Changes**: New in Zulip 10.0 (feature level 337).  (e.g. true)
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meeting_name" $meeting_name "scalar") (serialize-qp "voice_only" $voice_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calls/bigbluebutton/create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Nextcloud Talk video call
#
# POST /calls/nextcloud_talk/create
# operationId: create-nextcloud-talk-video-call
export def "calls-nextcloud-talk-create create-nextcloud-talk-video-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  room_name: string # Room name for the Nextcloud Talk conversation.  (e.g. #Test > team check-in)
]: any -> record<result: any, msg: any, ignored_parameters_unsupported: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls/nextcloud_talk/create")
  let body = {room_name: $room_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Webex video call
#
# POST /calls/webex/create
# operationId: create-webex-video-call
export def "calls-webex-create create-webex-video-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls/webex/create")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Constructor Groups video call
#
# POST /calls/constructorgroups/create
# operationId: create-constructor-groups-video-call
export def "calls-constructorgroups-create create-constructor-groups-video-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, msg: any, ignored_parameters_unsupported: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls/constructorgroups/create")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
