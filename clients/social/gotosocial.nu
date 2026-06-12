# Auto-generated client for GoToSocial Swagger documentation. vREPLACE_ME
# Source: https://docs.gotosocial.org/en/latest/api/swagger.yaml
# Auth: --token flag or $env.GOTOSOCIAL_SWAGGER_DOCUMENTATION_TOKEN

const BASE_URL = "https://example.org"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOTOSOCIAL_SWAGGER_DOCUMENTATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://example.org" "http://example.org"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["copy" "disable" "modify"] }
def media-policy-completer [] { ["mark_sensitive" "no_action" "reject"] }
def follows-policy-completer [] { ["manual_approval" "no_action" "reject_all" "reject_non_mutual"] }
def statuses-policy-completer [] { ["filter_hide" "filter_warn" "no_action"] }
def accounts-policy-completer [] { ["mute" "no_action"] }
def replies-policy-completer [] { ["followed" "list" "none"] }
def datapolicy-completer [] { ["all" "followed" "follower" "none"] }
def visibility-completer [] { ["direct" "mutuals_only" "private" "public" "unlisted"] }
def content-type-completer [] { ["text/markdown" "text/plain"] }
def stream-completer [] { ["direct" "hashtag" "hashtag:local" "list" "public" "public:local" "user" "user:notification"] }
def filter-action-completer [] { ["blur" "hide" "warn"] }
def accept-completer [] { ["application/json; profile="http://nodeinfo.diaspora.software/ns/schema/2.0#"" "application/json; profile="http://nodeinfo.diaspora.software/ns/schema/2.1#""] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "well-known-host-meta hostMetaGet" } } | get name | first)
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

# Returns a compliant hostmeta response to web host metadata queries.
#
# GET /.well-known/host-meta
# operationId: hostMetaGet
export def "well-known-host-meta hostMetaGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Link: table<href: string, rel: string, template: string, type: string>, XMLNS: string, XMLName: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/host-meta")
  let accept_val = "application/xrd+xml""
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a well-known response which redirects callers to `/nodeinfo/2.0`.
#
# GET /.well-known/nodeinfo
# operationId: nodeInfoWellKnownGet
export def "well-known-nodeinfo nodeInfoWellKnownGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: list<string>, links: table<href: string, rel: string, template: string, type: string>, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/nodeinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Handles webfinger account lookup requests.
#
# GET /.well-known/webfinger
# operationId: webfingerGet
export def "well-known-webfinger webfingerGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: list<string>, links: table<href: string, rel: string, template: string, type: string>, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/webfinger")
  let accept_val = "application/jrd+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a new media attachment.
#
# POST /api/{api_version}/media
# operationId: mediaCreate
export def "media mediaCreate" [
  api_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Image or media description to use as alt-text on the attachment. This is very useful for users of screenreaders! May or may not be required, depending on your instance settings.
  --focus: string # Focus of the media file. If present, it should be in the form of two comma-separated floats between -1 and 1. For example: `-0.5,0.25`.
  file: path # The media attachment to upload.
]: any -> record<blurhash: string, description: string, error: string, id: string, meta: record<focus: record<x: float, y: float>, original: record<aspect: float, bitrate: int, duration: float, frame_rate: string, height: int, size: string, width: int>, small: record<aspect: float, bitrate: int, duration: float, frame_rate: string, height: int, size: string, width: int>>, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/($api_version)/media")
  let body = {description: $description, focus: $focus, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Search for statuses, accounts, or hashtags, on this instance or elsewhere.
#
# GET /api/{api_version}/search
# operationId: searchGet
export def "search searchGet" [
  api_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only items *OLDER* than the given max ID. The item with the specified ID will not be included in the response. Currently only used if 'type' is set to a specific type.
  --min-id: string # Return only items *immediately newer* than the given min ID. The item with the specified ID will not be included in the response. Currently only used if 'type' is set to a specific type.
  --limit: int # Number of each type of item to return. (default: 20)
  --offset: int # Page number of results to return (starts at 0). This parameter is currently not used, page by selecting a specific query type and using maxID and minID instead. (default: 0)
  --q: string # Query string to search for. This can be in the following forms: - `@[username]` -- search for an account with the given username on any domain. Can return multiple results. - @[username]@[domain]` -- search for a remote account with exact username and domain. Will only ever return 1 result at most. - `https://example.org/some/arbitrary/url` -- search for an account OR a status with the given URL. Will only ever return 1 result at most. - `#[hashtag_name]` -- search for a hashtag with the given hashtag name, or starting with the given hashtag name. Case insensitive. Can return multiple results. - any arbitrary string -- search for accounts or statuses containing the given string. Can return multiple results.  Arbitrary string queries may include the following operators: - `from:localuser`, `from:remoteuser@instance.tld`: restrict results to statuses created by the specified account.
  --type: string # Type of item to return. One of: - `` -- empty string; return any/all results. - `accounts` -- return only account(s). - `statuses` -- return only status(es). - `hashtags` -- return only hashtag(s). If `type` is specified, paging can be performed using max_id and min_id parameters. If `type` is not specified, see the `offset` parameter for paging.
  --resolve: oneof<nothing, bool> # If searching query is for `@[username]@[domain]`, or a URL, allow the GoToSocial instance to resolve the search by making calls to remote instances (webfinger, ActivityPub, etc). (default: false)
  --following: oneof<nothing, bool> # If search type includes accounts, and search query is an arbitrary string, show only accounts that the requesting account follows. If this is set to `true`, then the GoToSocial instance will enhance the search by also searching within account notes, not just in usernames and display names. (default: false)
  --exclude-unreviewed: oneof<nothing, bool> # If searching for hashtags, exclude those not yet approved by instance admin. Currently this parameter is unused. (default: false)
  --account-id: string # Restrict results to statuses created by the specified account.
]: nothing -> record<accounts: table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, hashtags: list<any>, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "resolve" $resolve "scalar") (serialize-qp "following" $following "scalar") (serialize-qp "exclude_unreviewed" $exclude_unreviewed "scalar") (serialize-qp "account_id" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/($api_version)/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new account using an application token.
#
# POST /api/v1/accounts
# operationId: accountCreate
export def "accounts accountCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: string # Text that will be reviewed by moderators if registrations require manual approval.
  --username: string # The desired username for the account.
  --email: string # The email address to be used for login.
  --password: string # The password to be used for login. This will be hashed before storage.
  --agreement: oneof<nothing, bool> # The user agrees to the terms, conditions, and policies of the instance.
  --locale: string # The preferred language of the account user (optional).
]: nothing -> record<access_token: string, created_at: int, scope: string, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "agreement" $agreement "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about an account with the given ID.
#
# GET /api/v1/accounts/{id}
# operationId: accountGet
export def "accounts accountGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, enable_rss: bool, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: table<color: string, id: string, name: string>, source: record<also_known_as_uris: list<string>, fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Block account with id.
#
# POST /api/v1/accounts/{id}/block
# operationId: accountBlock
export def "accounts-block accountBlock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/block")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of target account's featured tags.
#
# GET /api/v1/accounts/{id}/featured_tags
# operationId: accountsFeaturedTags
export def "accounts-featured-tags accountsFeaturedTags" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/featured_tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Follow account with id.
#
# POST /api/v1/accounts/{id}/follow
# operationId: accountFollow
export def "accounts-follow accountFollow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reblogs: oneof<nothing, bool> # Show reblogs from this account.
  --notify: oneof<nothing, bool> # Notify when this account posts.
]: any -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/follow")
  let body = {reblogs: $reblogs, notify: $notify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# See followers of account with given id.
#
# GET /api/v1/accounts/{id}/followers
# operationId: accountFollowers
export def "accounts-followers accountFollowers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only follower accounts *OLDER* than the given max ID. The follower account with the specified ID will not be included in the response. NOTE: the ID is of the internal follow, NOT any of the returned accounts.
  --since-id: string # Return only follower accounts *NEWER* than the given since ID. The follower account with the specified ID will not be included in the response. NOTE: the ID is of the internal follow, NOT any of the returned accounts.
  --min-id: string # Return only follower accounts *IMMEDIATELY NEWER* than the given min ID. The follower account with the specified ID will not be included in the response. NOTE: the ID is of the internal follow, NOT any of the returned accounts.
  --limit: int # Number of follower accounts to return. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($id)/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See accounts followed by given account id.
#
# GET /api/v1/accounts/{id}/following
# operationId: accountFollowing
export def "accounts-following accountFollowing" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only following accounts *OLDER* than the given max ID. The following account with the specified ID will not be included in the response. NOTE: the ID is of the internal follow, NOT any of the returned accounts.
  --since-id: string # Return only following accounts *NEWER* than the given since ID. The following account with the specified ID will not be included in the response. NOTE: the ID is of the internal follow, NOT any of the returned accounts.
  --min-id: string # Return only following accounts *IMMEDIATELY NEWER* than the given min ID. The following account with the specified ID will not be included in the response. NOTE: the ID is of the internal follow, NOT any of the returned accounts.
  --limit: int # Number of following accounts to return. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($id)/following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See all lists of yours that contain requested account.
#
# GET /api/v1/accounts/{id}/lists
# operationId: accountLists
export def "accounts-lists accountLists" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<exclusive: bool, id: string, replies_policy: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mute account by ID.
#
# POST /api/v1/accounts/{id}/mute
# operationId: accountMute
export def "accounts-mute accountMute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notifications: oneof<nothing, bool> # Mute notifications as well as posts.
  --duration: float # How long the mute should last, in seconds. If 0 or not provided, mute lasts indefinitely.
]: any -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/mute")
  let body = {notifications: $notifications, duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set a private note for an account with the given id.
#
# POST /api/v1/accounts/{id}/note
# operationId: accountNote
export def "accounts-note accountNote" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # The text of the note. Omit this parameter or send an empty string to clear the note.
]: any -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/note")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# See statuses posted by the requested account.
#
# GET /api/v1/accounts/{id}/statuses
# operationId: accountStatuses
export def "accounts-statuses accountStatuses" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of statuses to return. (default: 30)
  --exclude-replies: oneof<nothing, bool> # Exclude statuses that are a reply to another status. (default: false)
  --exclude-reblogs: oneof<nothing, bool> # Exclude statuses that are a reblog/boost of another status. (default: false)
  --max-id: string # Return only statuses *OLDER* than the given max status ID. The status with the specified ID will not be included in the response.
  --min-id: string # Return only statuses *NEWER* than the given min status ID. The status with the specified ID will not be included in the response.
  --pinned: oneof<nothing, bool> # Show only pinned statuses. In other words, exclude statuses that are not pinned to the given account ID. (default: false)
  --only-media: oneof<nothing, bool> # Show only statuses with media attachments. (default: false)
  --only-public: oneof<nothing, bool> # Show only statuses with a privacy setting of 'public'. (default: false)
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "exclude_replies" $exclude_replies "scalar") (serialize-qp "exclude_reblogs" $exclude_reblogs "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "pinned" $pinned "scalar") (serialize-qp "only_media" $only_media "scalar") (serialize-qp "only_public" $only_public "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($id)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unblock account with ID.
#
# POST /api/v1/accounts/{id}/unblock
# operationId: accountUnblock
export def "accounts-unblock accountUnblock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/unblock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unfollow account with id.
#
# POST /api/v1/accounts/{id}/unfollow
# operationId: accountUnfollow
export def "accounts-unfollow accountUnfollow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/unfollow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unmute account by ID.
#
# POST /api/v1/accounts/{id}/unmute
# operationId: accountUnmute
export def "accounts-unmute accountUnmute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($id)/unmute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Alias your account to another account by setting alsoKnownAs to the given URI.
#
# POST /api/v1/accounts/alias
# operationId: accountAlias
export def "accounts-alias accountAlias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  also_known_as_uris: string # ActivityPub URI/IDs of target accounts to which this account is being aliased. Eg., `["https://example.org/users/some_account"]`. Use an empty array to unset alsoKnownAs, clearing the aliases.
]: any -> record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, enable_rss: bool, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: table<color: string, id: string, name: string>, source: record<also_known_as_uris: list<string>, fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/alias")
  let body = {also_known_as_uris: $also_known_as_uris} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete your account.
#
# POST /api/v1/accounts/delete
# operationId: accountDelete
export def "accounts-delete accountDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # Password of the account user, for confirmation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/delete")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Quickly lookup a username to see if it is available, skipping WebFinger resolution.
#
# GET /api/v1/accounts/lookup
# operationId: accountLookupGet
export def "accounts-lookup accountLookupGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acct: string # The username or Webfinger address to lookup.
]: nothing -> record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, enable_rss: bool, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: table<color: string, id: string, name: string>, source: record<also_known_as_uris: list<string>, fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acct" $acct "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move your account to another account.
#
# POST /api/v1/accounts/move
# operationId: accountMove
export def "accounts-move accountMove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # Password of the account user, for confirmation.
  moved_to_uri: string # ActivityPub URI/ID of the target account. Eg., `https://example.org/users/some_account`. The target account must be alsoKnownAs the requesting account in order for the move to be successful.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/move")
  let body = {password: $password, moved_to_uri: $moved_to_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# See your account's relationships with the given account IDs.
#
# GET /api/v1/accounts/relationships
# operationId: accountRelationships
export def "accounts-relationships accountRelationships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list # Account IDs.
]: nothing -> table<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id[]" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts/relationships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for accounts by username and/or display name.
#
# GET /api/v1/accounts/search
# operationId: accountSearchGet
export def "accounts-search accountSearchGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to try to return. (default: 40)
  --offset: int # Page number of results to return (starts at 0). This parameter is currently not used, offsets over 0 will always return 0 results. (default: 0)
  --q: string # Query string to search for. This can be in the following forms: - `@[username]` -- search for an account with the given username on any domain. Can return multiple results. - `@[username]@[domain]` -- search for a remote account with exact username and domain. Will only ever return 1 result at most. - any arbitrary string -- search for accounts containing the given string in their username or display name. Can return multiple results.
  --resolve: oneof<nothing, bool> # If query is for `@[username]@[domain]`, or a URL, allow the GoToSocial instance to resolve the search by making calls to remote instances (webfinger, ActivityPub, etc). (default: false)
  --following: oneof<nothing, bool> # Show only accounts that the requesting account follows. If this is set to `true`, then the GoToSocial instance will enhance the search by also searching within account notes, not just in usernames and display names. (default: false)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "resolve" $resolve "scalar") (serialize-qp "following" $following "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See preset CSS themes available to accounts on this instance.
#
# GET /api/v1/accounts/themes
# operationId: accountThemes
export def "accounts-themes accountThemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<description: string, file_name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/themes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update your account.
#
# PATCH /api/v1/accounts/update_credentials
# operationId: accountUpdate
export def "accounts-update-credentials accountUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --discoverable: oneof<nothing, bool> # Account should be made discoverable and shown in the profile directory (if enabled).
  --indexable: oneof<nothing, bool> # Account's posts should be made indexable by full-text search features (if enabled).
  --bot: oneof<nothing, bool> # Account is flagged as a bot.
  --display-name: string # The display name to use for the account.
  --note: string # Bio/description of this account.
  --avatar: path # Avatar of the user.
  --avatar-description: string # Description of avatar image, for alt-text.
  --header: path # Header of the user.
  --header-description: string # Description of header image, for alt-text.
  --locked: oneof<nothing, bool> # Require manual approval of follow requests.
  --sourceprivacy: string # Default post privacy for authored statuses.
  --sourcesensitive: oneof<nothing, bool> # Mark authored statuses as sensitive by default.
  --sourcelanguage: string # Default language to use for authored statuses (ISO 6391).
  --sourcestatus-content-type: string # Default content type to use for authored statuses (text/plain or text/markdown).
  --theme: string # FileName of the theme to use when rendering this account's profile or statuses. The theme must exist on this server, as indicated by /api/v1/accounts/themes. Empty string unsets theme and returns to the default GoToSocial theme.
  --custom-css: string # Custom CSS to use when rendering this account's profile or statuses. String must be no more than 5,000 characters (~5kb).
  --enable-rss: oneof<nothing, bool> # Enable RSS feed for this account's Public posts at `/[username]/feed.rss`
  --hide-collections: oneof<nothing, bool> # Hide the account's following/followers collections.
  --web-visibility: string # Posts to show on the web view of the account. "public": default, show only Public visibility posts on the web. "unlisted": show Public *and* Unlisted visibility posts on the web. "none": show no posts on the web, not even Public ones.
  --web-layout: string # Layout to use for the web view of the account. "microblog": default, classic microblog layout. "gallery": gallery layout with media only.
  --web-include-boosts: oneof<nothing, bool> # Include boosts created by the account on the web view of the account.
  --fields-attributes0name: string # Name of 1st profile field to be added to this account's profile. (The index may be any string; add more indexes to send more fields.)
  --fields-attributes0value: string # Value of 1st profile field to be added to this account's profile. (The index may be any string; add more indexes to send more fields.)
  --fields-attributes1name: string # Name of 2nd profile field to be added to this account's profile.
  --fields-attributes1value: string # Value of 2nd profile field to be added to this account's profile.
  --fields-attributes2name: string # Name of 3rd profile field to be added to this account's profile.
  --fields-attributes2value: string # Value of 3rd profile field to be added to this account's profile.
  --fields-attributes3name: string # Name of 4th profile field to be added to this account's profile.
  --fields-attributes3value: string # Value of 4th profile field to be added to this account's profile.
  --fields-attributes4name: string # Name of 5th profile field to be added to this account's profile.
  --fields-attributes4value: string # Value of 5th profile field to be added to this account's profile.
  --fields-attributes5name: string # Name of 6th profile field to be added to this account's profile.
  --fields-attributes5value: string # Value of 6th profile field to be added to this account's profile.
]: any -> record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, enable_rss: bool, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: table<color: string, id: string, name: string>, source: record<also_known_as_uris: list<string>, fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/update_credentials")
  let body = {discoverable: $discoverable, indexable: $indexable, bot: $bot, display_name: $display_name, note: $note, avatar: $avatar, avatar_description: $avatar_description, header: $header, header_description: $header_description, locked: $locked, source[privacy]: $sourceprivacy, source[sensitive]: $sourcesensitive, source[language]: $sourcelanguage, source[status_content_type]: $sourcestatus_content_type, theme: $theme, custom_css: $custom_css, enable_rss: $enable_rss, hide_collections: $hide_collections, web_visibility: $web_visibility, web_layout: $web_layout, web_include_boosts: $web_include_boosts, fields_attributes[0][name]: $fields_attributes0name, fields_attributes[0][value]: $fields_attributes0value, fields_attributes[1][name]: $fields_attributes1name, fields_attributes[1][value]: $fields_attributes1value, fields_attributes[2][name]: $fields_attributes2name, fields_attributes[2][value]: $fields_attributes2value, fields_attributes[3][name]: $fields_attributes3name, fields_attributes[3][value]: $fields_attributes3value, fields_attributes[4][name]: $fields_attributes4name, fields_attributes[4][value]: $fields_attributes4value, fields_attributes[5][name]: $fields_attributes5name, fields_attributes[5][value]: $fields_attributes5value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($avatar | is-not-empty) { $body | upsert avatar (open -r $avatar) } else { $body }
  let body = if ($header | is-not-empty) { $body | upsert header (open -r $header) } else { $body }
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Verify a token by returning account details pertaining to it.
#
# GET /api/v1/accounts/verify_credentials
# operationId: accountVerify
export def "accounts-verify-credentials accountVerify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, enable_rss: bool, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: table<color: string, id: string, name: string>, source: record<also_known_as_uris: list<string>, fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/verify_credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View + page through known accounts according to given filters.
#
# GET /api/v1/admin/accounts
# operationId: adminAccountsGetV1
export def "admin-accounts adminAccountsGetV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --local: oneof<nothing, bool> # Filter for local accounts. (default: false)
  --remote: oneof<nothing, bool> # Filter for remote accounts. (default: false)
  --active: oneof<nothing, bool> # Filter for currently active accounts. (default: false)
  --pending: oneof<nothing, bool> # Filter for currently pending accounts. (default: false)
  --disabled: oneof<nothing, bool> # Filter for currently disabled accounts. (default: false)
  --silenced: oneof<nothing, bool> # Filter for currently silenced accounts. (default: false)
  --suspended: oneof<nothing, bool> # Filter for currently suspended accounts. (default: false)
  --sensitized: oneof<nothing, bool> # Filter for accounts force-marked as sensitive. (default: false)
  --username: string # Search for the given username.
  --display-name: string # Search for the given display name.
  --by-domain: string # Filter by the given domain.
  --email: string # Lookup a user with this email.
  --ip: string # Lookup users with this IP address.
  --staff: oneof<nothing, bool> # Filter for staff accounts. (default: false)
  --max-id: string # max_id in the form `[domain]/@[username]`. All results returned will be later in the alphabet than `[domain]/@[username]`. For example, if max_id = `example.org/@someone` then returned entries might contain `example.org/@someone_else`, `later.example.org/@someone`, etc. Local account IDs in this form use an empty string for the `[domain]` part, for example local account with username `someone` would be `/@someone`.
  --min-id: string # min_id in the form `[domain]/@[username]`. All results returned will be earlier in the alphabet than `[domain]/@[username]`. For example, if min_id = `example.org/@someone` then returned entries might contain `example.org/@earlier_account`, `earlier.example.org/@someone`, etc. Local account IDs in this form use an empty string for the `[domain]` part, for example local account with username `someone` would be `/@someone`.
  --limit: int # Maximum number of results to return. (default: 50)
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "local" $local "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "pending" $pending "scalar") (serialize-qp "disabled" $disabled "scalar") (serialize-qp "silenced" $silenced "scalar") (serialize-qp "suspended" $suspended "scalar") (serialize-qp "sensitized" $sensitized "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "display_name" $display_name "scalar") (serialize-qp "by_domain" $by_domain "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ip" $ip "scalar") (serialize-qp "staff" $staff "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View one account.
#
# GET /api/v1/admin/accounts/{id}
# operationId: adminAccountGet
export def "admin-accounts adminAccountGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform an admin action on an account.
#
# POST /api/v1/admin/accounts/{id}/action
# operationId: adminAccountAction
export def "admin-accounts-action adminAccountAction" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string # Type of action to be taken, currently only supports `suspend`.
  --text: string # Optional text describing why this action was taken.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/accounts/($id)/action")
  let body = {type: $type, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Approve pending account.
#
# POST /api/v1/admin/accounts/{id}/approve
# operationId: adminAccountApprove
export def "admin-accounts-approve adminAccountApprove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/accounts/($id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject pending account.
#
# POST /api/v1/admin/accounts/{id}/reject
# operationId: adminAccountReject
export def "admin-accounts-reject adminAccountReject" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --private-comment: string # Comment to leave on why the account was denied. The comment will be visible to admins only.
  --message: string # Message to include in email to applicant. Will be included only if send_email is true.
  --send-email: oneof<nothing, bool> # Send an email to the applicant informing them that their sign-up has been rejected.
]: any -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/accounts/($id)/reject")
  let body = {private_comment: $private_comment, message: $message, send_email: $send_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View local and remote emojis available to / known by this instance.
#
# GET /api/v1/admin/custom_emojis
# operationId: emojisGet
export def "admin-custom-emojis emojisGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Comma-separated list of filters to apply to results. Recognized filters are:  `domain:[domain]` -- show emojis from the given domain, eg `?filter=domain:example.org` will show emojis from `example.org` only. Instead of giving a specific domain, you can also give either one of the key words `local` or `all` to show either local emojis only (`domain:local`) or show all emojis from all domains (`domain:all`). Note: `domain:*` is equivalent to `domain:all` (including local). If no domain filter is provided, `domain:all` will be assumed.  `disabled` -- include emojis that have been disabled.  `enabled` -- include emojis that are enabled.  `shortcode:[shortcode]` -- show only emojis with the given shortcode, eg `?filter=shortcode:blob_cat_uwu` will show only emojis with the shortcode `blob_cat_uwu` (case sensitive).  If neither `disabled` or `enabled` are provided, both disabled and enabled emojis will be shown.  If no filter query string is provided, the default `domain:all` will be used, which will show all emojis from all domains. (default: domain:all)
  --limit: int # Number of emojis to return. Less than 1, or not set, means unlimited (all emojis). (default: 50)
  --max-shortcode-domain: string # Return only emojis with `[shortcode]@[domain]` *LOWER* (alphabetically) than given `[shortcode]@[domain]`. For example, if `max_shortcode_domain=beep@example.org`, then returned values might include emojis with `[shortcode]@[domain]`s like `car@example.org`, `debian@aaa.com`, `test@` (local emoji), etc. Emoji with the given `[shortcode]@[domain]` will not be included in the result set.
  --min-shortcode-domain: string # Return only emojis with `[shortcode]@[domain]` *HIGHER* (alphabetically) than given `[shortcode]@[domain]`. For example, if `max_shortcode_domain=beep@example.org`, then returned values might include emojis with `[shortcode]@[domain]`s like `arse@test.com`, `0101_binary@hackers.net`, `bee@` (local emoji), etc. Emoji with the given `[shortcode]@[domain]` will not be included in the result set.
]: nothing -> table<category: string, content_type: string, disabled: bool, domain: string, id: string, shortcode: string, static_url: string, total_file_size: int, updated_at: string, uri: string, url: string, visible_in_picker: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "max_shortcode_domain" $max_shortcode_domain "scalar") (serialize-qp "min_shortcode_domain" $min_shortcode_domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/custom_emojis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload and create a new instance emoji.
#
# POST /api/v1/admin/custom_emojis
# operationId: emojiCreate
export def "admin-custom-emojis emojiCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  shortcode: string # The code to use for the emoji, which will be used by instance denizens to select it. This must be unique on the instance.
  image: path # A png or gif image of the emoji. Animated pngs work too! To ensure compatibility with other fedi implementations, emoji size limit is 50kb by default.
  --category: string # Category in which to place the new emoji. If left blank, emoji will be uncategorized. If a category with the given name doesn't exist yet, it will be created.
]: any -> record<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/custom_emojis")
  let body = {shortcode: $shortcode, image: $image, category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($image | is-not-empty) { $body | upsert image (open -r $image) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a **local** emoji with the given ID from the instance.
#
# DELETE /api/v1/admin/custom_emojis/{id}
# operationId: emojiDelete
export def "admin-custom-emojis emojiDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<category: string, content_type: string, disabled: bool, domain: string, id: string, shortcode: string, static_url: string, total_file_size: int, updated_at: string, uri: string, url: string, visible_in_picker: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/custom_emojis/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the admin view of a single emoji.
#
# GET /api/v1/admin/custom_emojis/{id}
# operationId: emojiGet
export def "admin-custom-emojis emojiGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<category: string, content_type: string, disabled: bool, domain: string, id: string, shortcode: string, static_url: string, total_file_size: int, updated_at: string, uri: string, url: string, visible_in_picker: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/custom_emojis/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform admin action on a local or remote emoji known to this instance.
#
# PATCH /api/v1/admin/custom_emojis/{id}
# operationId: emojiUpdate
export def "admin-custom-emojis emojiUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # Type of action to be taken. One of: (`disable`, `copy`, `modify`). For REMOTE emojis, `copy` or `disable` are supported. For LOCAL emojis, only `modify` is supported.
  --shortcode: string # The code to use for the emoji, which will be used by instance denizens to select it. This must be unique on the instance. Works for the `copy` action type only.
  --image: path # A new png or gif image to use for the emoji. Animated pngs work too! To ensure compatibility with other fedi implementations, emoji size limit is 50kb by default. Works for LOCAL emojis only.
  --category: string # Category in which to place the emoji. If a category with the given name doesn't exist yet, it will be created.
]: any -> record<category: string, content_type: string, disabled: bool, domain: string, id: string, shortcode: string, static_url: string, total_file_size: int, updated_at: string, uri: string, url: string, visible_in_picker: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/custom_emojis/($id)")
  let body = {type: $type, shortcode: $shortcode, image: $image, category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($image | is-not-empty) { $body | upsert image (open -r $image) } else { $body }
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a list of existing emoji categories.
#
# GET /api/v1/admin/custom_emojis/categories
# operationId: emojiCategoriesGet
export def "admin-custom-emojis-categories emojiCategoriesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/custom_emojis/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View all domain allows currently in place.
#
# GET /api/v1/admin/domain_allows
# operationId: domainAllowsGet
export def "admin-domain-allows domainAllowsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-export: oneof<nothing, bool> # If set to `true`, then each entry in the returned list of domain allows will only consist of the fields `domain` and `public_comment`. This is perfect for when you want to save and share a list of all the domains you have allowed on your instance, so that someone else can easily import them, but you don't want them to see the database IDs of your allows, or private comments etc.
]: nothing -> table<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "export" $qp_export "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_allows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create one or more domain allows, from a string or a file.
#
# POST /api/v1/admin/domain_allows
# operationId: domainAllowCreate
export def "admin-domain-allows domainAllowCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --import: oneof<nothing, bool> # Signal that a list of domain allows is being imported as a file. If set to `true`, then 'domains' must be present as a JSON-formatted file. If set to `false`, then `domains` will be ignored, and `domain` must be present. (default: false)
  --domains: path # JSON-formatted list of domain allows to import. This is only used if `import` is set to `true`.
  --domain: string # Single domain to allow. Used only if `import` is not `true`.
  --obfuscate: oneof<nothing, bool> # Obfuscate the name of the domain when serving it publicly. Eg., `example.org` becomes something like `ex***e.org`. Used only if `import` is not `true`.
  --public-comment: string # Public comment about this domain allow. This will be displayed alongside the domain allow if you choose to share allows. Used only if `import` is not `true`.
  --private-comment: string # Private comment about this domain allow. Will only be shown to other admins, so this is a useful way of internally keeping track of why a certain domain ended up allowed. Used only if `import` is not `true`.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "import" $import "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_allows" $qp)
  let body = {domains: $domains, domain: $domain, obfuscate: $obfuscate, public_comment: $public_comment, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($domains | is-not-empty) { $body | upsert domains (open -r $domains) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete domain allow with the given ID.
#
# DELETE /api/v1/admin/domain_allows/{id}
# operationId: domainAllowDelete
export def "admin-domain-allows domainAllowDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_allows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View domain allow with the given ID.
#
# GET /api/v1/admin/domain_allows/{id}
# operationId: domainAllowGet
export def "admin-domain-allows domainAllowGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_allows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single domain allow.
#
# PUT /api/v1/admin/domain_allows/{id}
# operationId: domainAllowUpdate
export def "admin-domain-allows domainAllowUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --obfuscate: oneof<nothing, bool> # Obfuscate the name of the domain when serving it publicly. Eg., `example.org` becomes something like `ex***e.org`.
  --public-comment: string # Public comment about this domain allow. This will be displayed alongside the domain allow if you choose to share allows.
  --private-comment: string # Private comment about this domain allow. Will only be shown to other admins, so this is a useful way of internally keeping track of why a certain domain ended up allowed.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_allows/($id)")
  let body = {obfuscate: $obfuscate, public_comment: $public_comment, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View all domain blocks currently in place.
#
# GET /api/v1/admin/domain_blocks
# operationId: domainBlocksGet
export def "admin-domain-blocks domainBlocksGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-export: oneof<nothing, bool> # If set to `true`, then each entry in the returned list of domain blocks will only consist of the fields `domain` and `public_comment`. This is perfect for when you want to save and share a list of all the domains you have blocked on your instance, so that someone else can easily import them, but you don't want them to see the database IDs of your blocks, or private comments etc.
]: nothing -> table<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "export" $qp_export "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create one or more domain blocks, from a string or a file.
#
# POST /api/v1/admin/domain_blocks
# operationId: domainBlockCreate
export def "admin-domain-blocks domainBlockCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --import: oneof<nothing, bool> # Signal that a list of domain blocks is being imported as a file. If set to `true`, then 'domains' must be present as a JSON-formatted file. If set to `false`, then `domains` will be ignored, and `domain` must be present. (default: false)
  --domains: path # JSON-formatted list of domain blocks to import. This is only used if `import` is set to `true`.
  --domain: string # Single domain to block. Used only if `import` is not `true`.
  --obfuscate: oneof<nothing, bool> # Obfuscate the name of the domain when serving it publicly. Eg., `example.org` becomes something like `ex***e.org`. Used only if `import` is not `true`.
  --public-comment: string # Public comment about this domain block. This will be displayed alongside the domain block if you choose to share blocks. Used only if `import` is not `true`.
  --private-comment: string # Private comment about this domain block. Will only be shown to other admins, so this is a useful way of internally keeping track of why a certain domain ended up blocked. Used only if `import` is not `true`.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "import" $import "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_blocks" $qp)
  let body = {domains: $domains, domain: $domain, obfuscate: $obfuscate, public_comment: $public_comment, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($domains | is-not-empty) { $body | upsert domains (open -r $domains) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete domain block with the given ID.
#
# DELETE /api/v1/admin/domain_blocks/{id}
# operationId: domainBlockDelete
export def "admin-domain-blocks domainBlockDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View domain block with the given ID.
#
# GET /api/v1/admin/domain_blocks/{id}
# operationId: domainBlockGet
export def "admin-domain-blocks domainBlockGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single domain block.
#
# PUT /api/v1/admin/domain_blocks/{id}
# operationId: domainBlockUpdate
export def "admin-domain-blocks domainBlockUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --obfuscate: oneof<nothing, bool> # Obfuscate the name of the domain when serving it publicly. Eg., `example.org` becomes something like `ex***e.org`.
  --public-comment: string # Public comment about this domain block. This will be displayed alongside the domain block if you choose to share blocks.
  --private-comment: string # Private comment about this domain block. Will only be shown to other admins, so this is a useful way of internally keeping track of why a certain domain ended up blocked.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_blocks/($id)")
  let body = {obfuscate: $obfuscate, public_comment: $public_comment, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Force expiry of cached public keys for all accounts on the given domain stored in your database.
#
# POST /api/v1/admin/domain_keys_expire
# operationId: domainKeysExpire
export def "admin-domain-keys-expire domainKeysExpire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Domain to expire keys for. Sample: example.org
]: any -> record<action_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/domain_keys_expire")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View domain limits currently in place.
#
# GET /api/v1/admin/domain_limits
# operationId: domainLimitsGet
export def "admin-domain-limits domainLimitsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only items *OLDER* than the given max ID (for paging downwards). The item with the specified ID will not be included in the response.
  --since-id: string # Return only items *NEWER* than the given since ID. The item with the specified ID will not be included in the response.
  --min-id: string # Return only items immediately *NEWER* than the given min ID (for paging upwards). The item with the specified ID will not be included in the response.
  --limit: int # Number of items to return. Use 0 to return all (no paging). (default: 20)
]: nothing -> table<accounts_policy: string, content_warning: string, created_at: string, created_by: string, domain: string, follows_policy: string, id: string, media_policy: string, private_comment: string, public_comment: string, statuses_policy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_limits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a domain limit.
#
# POST /api/v1/admin/domain_limits
# operationId: domainLimitCreate
export def "admin-domain-limits domainLimitCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string # Hostname of the domain to limit.
  --media-policy: string@media-policy-completer # Policy to apply to media files originating from the limited domain. No action = default (not limited). Mark sensitive = mark all media from the limited domain as sensitive. Reject = do not download media from the limited domain. Serve a link to the media instead.
  --follows-policy: string@follows-policy-completer # Policy to apply to follow (requests) originating from the limited domain. No action = default (not limited). Manual approval = require manual approval for all follows from limited domain. Reject non mutual = automatically reject follows from the limited domain when they're not follow-backs. Reject all = automatically reject all follows from the limited domain.
  --statuses-policy: string@statuses-policy-completer # Policy to apply to statuses of non-followed accounts on the limited domain. No action = default (not limited). Filter warn = trigger a warn filter pointing to this domain limit. Filter hide = trigger a hide filter pointing to this domain limit.
  --accounts-policy: string@accounts-policy-completer # Policy to apply to non-followed accounts on the limited domain. No action = default (not limited). Mute = mute all non-followed accounts on the limited domain.
  --content-warning: string # Content warning to prepend to posts from accounts on this instance.
  --public-comment: string # Public comment about this domain limit. This will be displayed alongside the domain limit if you choose to share limits.
  --private-comment: string # Private comment about this domain limit. Will only be shown to other admins, so this is a useful way of internally keeping track of why a certain domain ended up limited.
]: any -> record<accounts_policy: string, content_warning: string, created_at: string, created_by: string, domain: string, follows_policy: string, id: string, media_policy: string, private_comment: string, public_comment: string, statuses_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/domain_limits")
  let body = {domain: $domain, media_policy: $media_policy, follows_policy: $follows_policy, statuses_policy: $statuses_policy, accounts_policy: $accounts_policy, content_warning: $content_warning, public_comment: $public_comment, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete domain limit with the given ID.
#
# DELETE /api/v1/admin/domain_limits/{id}
# operationId: domainLimitDelete
export def "admin-domain-limits domainLimitDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accounts_policy: string, content_warning: string, created_at: string, created_by: string, domain: string, follows_policy: string, id: string, media_policy: string, private_comment: string, public_comment: string, statuses_policy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_limits/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a domain limit.
#
# PUT /api/v1/admin/domain_limits/{id}
# operationId: domainLimitUpdate
export def "admin-domain-limits domainLimitUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --media-policy: string@media-policy-completer # Policy to apply to media files originating from the limited domain. No action = default (not limited). Mark sensitive = mark all media from the limited domain as sensitive. Reject = do not download media from the limited domain. Serve a link to the media instead. Omit to keep current value.
  --follows-policy: string@follows-policy-completer # Policy to apply to follow (requests) originating from the limited domain. No action = default (not limited). Manual approval = require manual approval for all follows from limited domain. Reject non mutual = automatically reject follows from the limited domain when they're not follow-backs. Reject all = automatically reject all follows from the limited domain. Omit to keep current value.
  --statuses-policy: string@statuses-policy-completer # Policy to apply to statuses of non-followed accounts on the limited domain. No action = default (not limited). Filter warn = trigger a warn filter pointing to this domain limit. Filter hide = trigger a hide filter pointing to this domain limit. Omit to keep current value.
  --accounts-policy: string@accounts-policy-completer # Policy to apply to non-followed accounts on the limited domain. No action = default (not limited). Mute = mute all non-followed accounts on the limited domain. Omit to keep current value.
  --content-warning: string # Content warning to prepend to posts from accounts on this instance. Omit to keep current value.
  --public-comment: string # Public comment about this domain limit. This will be displayed alongside the domain limit if you choose to share limits. Omit to keep current value.
  --private-comment: string # Private comment about this domain limit. Will only be shown to other admins, so this is a useful way of internally keeping track of why a certain domain ended up limited. Omit to keep current value.
]: any -> record<accounts_policy: string, content_warning: string, created_at: string, created_by: string, domain: string, follows_policy: string, id: string, media_policy: string, private_comment: string, public_comment: string, statuses_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_limits/($id)")
  let body = {media_policy: $media_policy, follows_policy: $follows_policy, statuses_policy: $statuses_policy, accounts_policy: $accounts_policy, content_warning: $content_warning, public_comment: $public_comment, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View domain permission drafts.
#
# GET /api/v1/admin/domain_permission_drafts
# operationId: domainPermissionDraftsGet
export def "admin-domain-permission-drafts domainPermissionDraftsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscription-id: string # Show only drafts created by the given subscription ID.
  --domain: string # Return only drafts that target the given domain.
  --permission-type: string # Filter on "block" or "allow" type drafts.
  --max-id: string # Return only items *OLDER* than the given max ID (for paging downwards). The item with the specified ID will not be included in the response.
  --since-id: string # Return only items *NEWER* than the given since ID. The item with the specified ID will not be included in the response.
  --min-id: string # Return only items immediately *NEWER* than the given min ID (for paging upwards). The item with the specified ID will not be included in the response.
  --limit: int # Number of items to return. (default: 20)
]: nothing -> table<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_id" $subscription_id "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "permission_type" $permission_type "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_permission_drafts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a domain permission draft with the given parameters.
#
# POST /api/v1/admin/domain_permission_drafts
# operationId: domainPermissionDraftCreate
export def "admin-domain-permission-drafts domainPermissionDraftCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Domain to create the permission draft for.
  --permission-type: string # Create a draft "allow" or a draft "block".
  --obfuscate: oneof<nothing, bool> # Obfuscate the name of the domain when serving it publicly. Eg., `example.org` becomes something like `ex***e.org`.
  --public-comment: string # Public comment about this domain permission. This will be displayed alongside the domain permission if you choose to share permissions.
  --private-comment: string # Private comment about this domain permission. Will only be shown to other admins, so this is a useful way of internally keeping track of why a certain domain ended up permissioned.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/domain_permission_drafts")
  let body = {domain: $domain, permission_type: $permission_type, obfuscate: $obfuscate, public_comment: $public_comment, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get domain permission draft with the given ID.
#
# GET /api/v1/admin/domain_permission_drafts/{id}
# operationId: domainPermissionDraftGet
export def "admin-domain-permission-drafts domainPermissionDraftGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_drafts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept a domain permission draft, turning it into an enforced domain permission.
#
# POST /api/v1/admin/domain_permission_drafts/{id}/accept
# operationId: domainPermissionDraftAccept
export def "admin-domain-permission-drafts-accept domainPermissionDraftAccept" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overwrite: oneof<nothing, bool> # If a domain permission already exists with the same domain and permission type as the draft, overwrite the existing permission with fields from the draft.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_drafts/($id)/accept")
  let body = {overwrite: $overwrite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a domain permission draft, optionally ignoring all future drafts targeting the given domain.
#
# POST /api/v1/admin/domain_permission_drafts/{id}/remove
# operationId: domainPermissionDraftRemove
export def "admin-domain-permission-drafts-remove domainPermissionDraftRemove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exclude-target: oneof<nothing, bool> # When removing the domain permission draft, also create a domain exclude entry for the target domain, so that drafts will not be created for this domain in the future.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_drafts/($id)/remove")
  let body = {exclude_target: $exclude_target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View domain permission excludes.
#
# GET /api/v1/admin/domain_permission_excludes
# operationId: domainPermissionExcludesGet
export def "admin-domain-permission-excludes domainPermissionExcludesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Return only excludes that target the given domain.
  --max-id: string # Return only items *OLDER* than the given max ID (for paging downwards). The item with the specified ID will not be included in the response.
  --since-id: string # Return only items *NEWER* than the given since ID. The item with the specified ID will not be included in the response.
  --min-id: string # Return only items immediately *NEWER* than the given min ID (for paging upwards). The item with the specified ID will not be included in the response.
  --limit: int # Number of items to return. (default: 20)
]: nothing -> table<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_permission_excludes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a domain permission exclude with the given parameters.
#
# POST /api/v1/admin/domain_permission_excludes
# operationId: domainPermissionExcludeCreate
export def "admin-domain-permission-excludes domainPermissionExcludeCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Domain to create the permission exclude for.
  --private-comment: string # Private comment about this domain exclude.
]: any -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/domain_permission_excludes")
  let body = {domain: $domain, private_comment: $private_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a domain permission exclude.
#
# DELETE /api/v1/admin/domain_permission_excludes/{id}
# operationId: domainPermissionExcludeDelete
export def "admin-domain-permission-excludes domainPermissionExcludeDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_excludes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get domain permission exclude with the given ID.
#
# GET /api/v1/admin/domain_permission_excludes/{id}
# operationId: domainPermissionExcludeGet
export def "admin-domain-permission-excludes domainPermissionExcludeGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: string, created_at: string, created_by: string, domain: string, id: string, obfuscate: bool, permission_type: string, private_comment: string, public_comment: string, severity: string, silenced_at: string, subscription_id: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_excludes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View domain permission subscriptions.
#
# GET /api/v1/admin/domain_permission_subscriptions
# operationId: domainPermissionSubscriptionsGet
export def "admin-domain-permission-subscriptions domainPermissionSubscriptionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission-type: string # Filter on "block" or "allow" type subscriptions.
  --max-id: string # Return only items *OLDER* than the given max ID (for paging downwards). The item with the specified ID will not be included in the response.
  --since-id: string # Return only items *NEWER* than the given since ID. The item with the specified ID will not be included in the response.
  --min-id: string # Return only items immediately *NEWER* than the given min ID (for paging upwards). The item with the specified ID will not be included in the response.
  --limit: int # Number of items to return. (default: 20)
]: nothing -> table<adopt_orphans: bool, as_draft: bool, content_type: string, count: int, created_at: string, created_by: string, error: string, fetch_password: string, fetch_username: string, fetched_at: string, id: string, permission_type: string, priority: int, remove_retracted: bool, successfully_fetched_at: string, title: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permission_type" $permission_type "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_permission_subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a domain permission subscription with the given parameters.
#
# POST /api/v1/admin/domain_permission_subscriptions
# operationId: domainPermissionSubscriptionCreate
export def "admin-domain-permission-subscriptions domainPermissionSubscriptionCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --priority: float # Priority of this subscription compared to others of the same permission type. 0-255 (higher = higher priority). Higher priority subscriptions will overwrite permissions generated by lower priority subscriptions. When two subscriptions have the same `priority` value, priority is indeterminate, so it's recommended to always set this value manually.
  --title: string # Optional title for this subscription.
  permission_type: string # Type of permissions to create by parsing the targeted file/list. One of "allow" or "block".
  --as-draft: oneof<nothing, bool> # If true, domain permissions arising from this subscription will be created as drafts that must be approved by a moderator to take effect. If false, domain permissions from this subscription will come into force immediately. Defaults to "true".
  --adopt-orphans: oneof<nothing, bool> # If true, this domain permission subscription will "adopt" domain permissions which already exist on the instance, and which meet the following conditions: 1) they have no subscription ID (ie., they're "orphaned") and 2) they are present in the subscribed list. Such orphaned domain permissions will be given this subscription's subscription ID value and be managed by this subscription.
  --remove-retracted: oneof<nothing, bool> # If true, then when a list is processed, if the list does *not* contain entries that it *did* contain previously, ie., retracted entries, then domain permissions corresponding to those entries will be removed. If false, they will just be orphaned instead.
  uri: string # URI to call in order to fetch the permissions list.
  content_type: string # MIME content type to use when parsing the permissions list. One of "text/plain", "text/csv", and "application/json".
  --fetch-username: string # Optional basic auth username to provide when fetching given uri. If set, will be transmitted along with `fetch_password` when doing the fetch.
  --fetch-password: string # Optional basic auth password to provide when fetching given uri. If set, will be transmitted along with `fetch_username` when doing the fetch.
]: any -> record<adopt_orphans: bool, as_draft: bool, content_type: string, count: int, created_at: string, created_by: string, error: string, fetch_password: string, fetch_username: string, fetched_at: string, id: string, permission_type: string, priority: int, remove_retracted: bool, successfully_fetched_at: string, title: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/domain_permission_subscriptions")
  let body = {priority: $priority, title: $title, permission_type: $permission_type, as_draft: $as_draft, adopt_orphans: $adopt_orphans, remove_retracted: $remove_retracted, uri: $uri, content_type: $content_type, fetch_username: $fetch_username, fetch_password: $fetch_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update a domain permission subscription with the given parameters.
#
# PATCH /api/v1/admin/domain_permission_subscriptions/${id}
# operationId: domainPermissionSubscriptionUpdate
export def "admin-domain-permission-subscriptions-id domainPermissionSubscriptionUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --priority: float # Priority of this subscription compared to others of the same permission type. 0-255 (higher = higher priority). Higher priority subscriptions will overwrite permissions generated by lower priority subscriptions. When two subscriptions have the same `priority` value, priority is indeterminate, so it's recommended to always set this value manually.
  --title: string # Optional title for this subscription.
  --uri: string # URI to call in order to fetch the permissions list.
  --as-draft: oneof<nothing, bool> # If true, domain permissions arising from this subscription will be created as drafts that must be approved by a moderator to take effect. If false, domain permissions from this subscription will come into force immediately. Defaults to "true".
  --adopt-orphans: oneof<nothing, bool> # If true, this domain permission subscription will "adopt" domain permissions which already exist on the instance, and which meet the following conditions: 1) they have no subscription ID (ie., they're "orphaned") and 2) they are present in the subscribed list. Such orphaned domain permissions will be given this subscription's subscription ID value and be managed by this subscription.
  --remove-retracted: oneof<nothing, bool> # If true, then when a list is processed, if the list does *not* contain entries that it *did* contain previously, ie., retracted entries, then domain permissions corresponding to those entries will be removed. If false, they will just be orphaned instead.
  --content-type: string # MIME content type to use when parsing the permissions list. One of "text/plain", "text/csv", and "application/json".
  --fetch-username: string # Optional basic auth username to provide when fetching given uri. If set, will be transmitted along with `fetch_password` when doing the fetch.
  --fetch-password: string # Optional basic auth password to provide when fetching given uri. If set, will be transmitted along with `fetch_username` when doing the fetch.
]: any -> record<adopt_orphans: bool, as_draft: bool, content_type: string, count: int, created_at: string, created_by: string, error: string, fetch_password: string, fetch_username: string, fetched_at: string, id: string, permission_type: string, priority: int, remove_retracted: bool, successfully_fetched_at: string, title: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_subscriptions/$($id)")
  let body = {priority: $priority, title: $title, uri: $uri, as_draft: $as_draft, adopt_orphans: $adopt_orphans, remove_retracted: $remove_retracted, content_type: $content_type, fetch_username: $fetch_username, fetch_password: $fetch_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get domain permission subscription with the given ID.
#
# GET /api/v1/admin/domain_permission_subscriptions/{id}
# operationId: domainPermissionSubscriptionGet
export def "admin-domain-permission-subscriptions domainPermissionSubscriptionGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<adopt_orphans: bool, as_draft: bool, content_type: string, count: int, created_at: string, created_by: string, error: string, fetch_password: string, fetch_username: string, fetched_at: string, id: string, permission_type: string, priority: int, remove_retracted: bool, successfully_fetched_at: string, title: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a domain permission subscription.
#
# POST /api/v1/admin/domain_permission_subscriptions/{id}/remove
# operationId: domainPermissionSubscriptionRemove
export def "admin-domain-permission-subscriptions-remove domainPermissionSubscriptionRemove" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --remove-children: oneof<nothing, bool> # When removing the domain permission subscription, also remove children of this subscription, ie., domain permissions that are managed by this subscription. If false, then children will instead be orphaned but not removed. Note that removed permissions may end up being created again later by another domain permission subscription of lower priority than the removed subscription. Likewise, orphaned children may be later adopted by another subscription.
]: any -> record<adopt_orphans: bool, as_draft: bool, content_type: string, count: int, created_at: string, created_by: string, error: string, fetch_password: string, fetch_username: string, fetched_at: string, id: string, permission_type: string, priority: int, remove_retracted: bool, successfully_fetched_at: string, title: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_subscriptions/($id)/remove")
  let body = {remove_children: $remove_children} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Test one domain permission subscription by making your instance fetch and parse it *without creating permissions*.
#
# POST /api/v1/admin/domain_permission_subscriptions/{id}/test
# operationId: domainPermissionSubscriptionTest
export def "admin-domain-permission-subscriptions-test domainPermissionSubscriptionTest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<comment: string, domain: string, public_comment: string, severity: string, silenced_at: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/domain_permission_subscriptions/($id)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View all domain permission subscriptions of the given permission type, in priority order (highest to lowest).
#
# GET /api/v1/admin/domain_permission_subscriptions/preview
# operationId: domainPermissionSubscriptionsPreviewGet
export def "admin-domain-permission-subscriptions-preview domainPermissionSubscriptionsPreviewGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission-type: string # Filter on "block" or "allow" type subscriptions.
]: nothing -> table<adopt_orphans: bool, as_draft: bool, content_type: string, count: int, created_at: string, created_by: string, error: string, fetch_password: string, fetch_username: string, fetched_at: string, id: string, permission_type: string, priority: int, remove_retracted: bool, successfully_fetched_at: string, title: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permission_type" $permission_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/domain_permission_subscriptions/preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a generic test email to a specified email address.
#
# POST /api/v1/admin/email/test
# operationId: testEmailSend
export def "admin-email-test testEmailSend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address that the test email should be sent to.
  --message: string # Optional message to include in the email.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/email/test")
  let body = {email: $email, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all "allow" header filters currently in place.
#
# GET /api/v1/admin/header_allows
# operationId: headerFilterAllowsGet
export def "admin-header-allows headerFilterAllowsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<created_at: string, created_by: string, header: string, id: string, regex: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/header_allows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new "allow" HTTP request header filter.
#
# POST /api/v1/admin/header_allows
# operationId: headerFilterAllowCreate
export def "admin-header-allows headerFilterAllowCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  header: string # The HTTP header to match against (e.g. User-Agent).
  regex: string # The header value matching regular expression.
]: any -> record<created_at: string, created_by: string, header: string, id: string, regex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/header_allows")
  let body = {header: $header, regex: $regex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete the "allow" header filter with the given ID.
#
# DELETE /api/v1/admin/header_allows/{id}
# operationId: headerFilterAllowDelete
export def "admin-header-allows headerFilterAllowDelete" [
  id: string
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
  let full_url = (build-url $base $"/api/v1/admin/header_allows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get "allow" header filter with the given ID.
#
# GET /api/v1/admin/header_allows/{id}
# operationId: headerFilterAllowGet
export def "admin-header-allows headerFilterAllowGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, created_by: string, header: string, id: string, regex: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/header_allows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all "allow" header filters currently in place.
#
# GET /api/v1/admin/header_blocks
# operationId: headerFilterBlocksGet
export def "admin-header-blocks headerFilterBlocksGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<created_at: string, created_by: string, header: string, id: string, regex: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/header_blocks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new "block" HTTP request header filter.
#
# POST /api/v1/admin/header_blocks
# operationId: headerFilterBlockCreate
export def "admin-header-blocks headerFilterBlockCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  header: string # The HTTP header to match against (e.g. User-Agent).
  regex: string # The header value matching regular expression.
]: any -> record<created_at: string, created_by: string, header: string, id: string, regex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/header_blocks")
  let body = {header: $header, regex: $regex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete the "block" header filter with the given ID.
#
# DELETE /api/v1/admin/header_blocks/{id}
# operationId: headerFilterBlockDelete
export def "admin-header-blocks headerFilterBlockDelete" [
  id: string
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
  let full_url = (build-url $base $"/api/v1/admin/header_blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get "block" header filter with the given ID.
#
# GET /api/v1/admin/header_blocks/{id}
# operationId: headerFilterBlockGet
export def "admin-header-blocks headerFilterBlockGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, created_by: string, header: string, id: string, regex: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/header_blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View instance rules, with IDs.
#
# GET /api/v1/admin/instance/rules
# operationId: adminsRuleGet
export def "admin-instance-rules adminsRuleGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/instance/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new instance rule.
#
# POST /api/v1/admin/instance/rules
# operationId: ruleCreate
export def "admin-instance-rules ruleCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string # Text body for the instance rule, plaintext.
]: any -> record<id: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/instance/rules")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an existing instance rule.
#
# DELETE /api/v1/admin/instance/rules/{id}
# operationId: ruleDelete
export def "admin-instance-rules ruleDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/instance/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View instance rule with the given id.
#
# GET /api/v1/admin/instance/rules/{id}
# operationId: adminRuleGet
export def "admin-instance-rules adminRuleGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/instance/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing instance rule.
#
# PATCH /api/v1/admin/instance/rules/{id}
# operationId: ruleUpdate
export def "admin-instance-rules ruleUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string # Text body for the updated instance rule, plaintext.
]: any -> record<id: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/instance/rules/($id)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Show admin view of instances.
#
# GET /api/v1/admin/instances
# operationId: adminInstances
export def "admin-instances adminInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Filter by the given domain.
  --order: string # Order by default "first_seen" (newest -> oldest) or "alphabetical" (a -> z). (default: latest)
  --with-errors-only: oneof<nothing, bool> # Only include instances that have one or more delivery errors since the last successful delivery. (default: false)
  --max-id: string # Return only items *OLDER* than the given max ID (for paging downwards). The item with the specified ID will not be included in the response.
  --since-id: string # Return only items *NEWER* than the given since ID. The item with the specified ID will not be included in the response.
  --min-id: string # Return only items immediately *NEWER* than the given min ID (for paging upwards). The item with the specified ID will not be included in the response.
  --limit: int # Number of items to return. (default: 40)
]: nothing -> table<delivery_errors: list<record>, domain: string, first_seen: string, id: string, latest_successful_delivery: string, software: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "with_errors_only" $with_errors_only "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show admin view of one instance.
#
# GET /api/v1/admin/instances/{id}
# operationId: adminInstanceGet
export def "admin-instances adminInstanceGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<delivery_errors: table<error: string, time: string>, domain: string, first_seen: string, id: string, latest_successful_delivery: string, software: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/instances/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clear delivery errors for instance with given ID.
#
# POST /api/v1/admin/instances/{id}/clear_delivery_errors
# operationId: adminInstanceClearDeliveryErrors
export def "admin-instances-clear-delivery-errors adminInstanceClearDeliveryErrors" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<delivery_errors: table<error: string, time: string>, domain: string, first_seen: string, id: string, latest_successful_delivery: string, software: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/instances/($id)/clear_delivery_errors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clean up remote media older than the specified number of days.
#
# POST /api/v1/admin/media_cleanup
# operationId: mediaCleanup
export def "admin-media-cleanup mediaCleanup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --remote-cache-days: string # Integer number of days, or duration string, of duration of remote media to keep. If value is not specified, the value of media-remote-cache-days in the server config will be used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remote_cache_days" $remote_cache_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/media_cleanup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purge all media (attachments, avatars, headers, emojis) from the given domain, completely removing them from storage.
#
# POST /api/v1/admin/media_purge
# operationId: mediaPurge
export def "admin-media-purge mediaPurge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Domain to purge media from.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/media_purge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refetch media specified in the database but missing from storage.
#
# POST /api/v1/admin/media_refetch
# operationId: mediaRefetch
export def "admin-media-refetch mediaRefetch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # Domain to refetch media from. If empty, all domains will be refetched.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/media_refetch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View relay subscriptions.
#
# GET /api/v1/admin/relay_subscriptions
# operationId: adminRelaySubscriptions
export def "admin-relay-subscriptions adminRelaySubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: list<record>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/relay_subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new relay subscription targeting a remote relay actor URI.
#
# POST /api/v1/admin/relay_subscriptions
# operationId: relaySubscriptionCreate
export def "admin-relay-subscriptions relaySubscriptionCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  relay_actor_uri: string # The ActivityPub URI of the remote relay actor.
  --public: oneof<nothing, bool> # Ingest public posts. If false, never ingest public posts via this subscription.
  --unlisted: oneof<nothing, bool> # Ingest unlisted posts. If false, never ingest unlisted posts via this subscription.
  --match-by-default: oneof<nothing, bool> # Controls whether the relay subscription should ingest all non-ignored posts by default. If set true, and no "exclude"-type matchers are set on the subscription, then all included, non-ignored posts will be ingested.
  --ignore-sensitive: oneof<nothing, bool> # Never ingest sensitive posts via this subscription.
  --ignore-media: oneof<nothing, bool> # Never ingest posts with media attachments via this subscription.
  --ignore-replies: oneof<nothing, bool> # Never ingest non-self-replies (ie., comments) via this subscription.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/admin/relay_subscriptions")
  let body = {relay_actor_uri: $relay_actor_uri, public: $public, unlisted: $unlisted, match_by_default: $match_by_default, ignore_sensitive: $ignore_sensitive, ignore_media: $ignore_media, ignore_replies: $ignore_replies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete relay subscription with the given ID.
#
# DELETE /api/v1/admin/relay_subscriptions/{id}
# operationId: adminRelaySubscriptionDelete
export def "admin-relay-subscriptions adminRelaySubscriptionDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/relay_subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View relay subscription with the given ID.
#
# GET /api/v1/admin/relay_subscriptions/{id}
# operationId: adminRelaySubscriptionGet
export def "admin-relay-subscriptions adminRelaySubscriptionGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/relay_subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a relay subscription.
#
# PUT /api/v1/admin/relay_subscriptions/{id}
# operationId: relaySubscriptionUpdate
export def "admin-relay-subscriptions relaySubscriptionUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --public: oneof<nothing, bool> # Ingest public posts. If false, never ingest public posts via this subscription.
  --unlisted: oneof<nothing, bool> # Ingest unlisted posts. If false, never ingest unlisted posts via this subscription.
  --match-by-default: oneof<nothing, bool> # Controls whether the relay subscription should ingest all non-ignored posts by default. If set true, and no "exclude"-type matchers are set on the subscription, then all included, non-ignored posts will be ingested.
  --ignore-sensitive: oneof<nothing, bool> # Never ingest sensitive posts via this subscription.
  --ignore-media: oneof<nothing, bool> # Never ingest posts with media attachments via this subscription.
  --ignore-replies: oneof<nothing, bool> # Never ingest non-self-replies (ie., comments) via this subscription.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/relay_subscriptions/($id)")
  let body = {public: $public, unlisted: $unlisted, match_by_default: $match_by_default, ignore_sensitive: $ignore_sensitive, ignore_media: $ignore_media, ignore_replies: $ignore_replies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add a relay matcher to a relay subscription.
#
# POST /api/v1/admin/relay_subscriptions/{id}/matchers
# operationId: relaySubscriptionMatcherPost
export def "admin-relay-subscriptions-matchers relaySubscriptionMatcherPost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyword: string # The text to be matched.
  --whole-word: oneof<nothing, bool> # Matcher should consider word boundaries.
  --exclude: oneof<nothing, bool> # Matcher should cause matched posts to be excluded from relaying rather than included.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/relay_subscriptions/($id)/matchers")
  let body = {keyword: $keyword, whole_word: $whole_word, exclude: $exclude} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a relay matcher from a relay subscription.
#
# DELETE /api/v1/admin/relay_subscriptions/{id}/matchers/{matcher_id}
# operationId: relaySubscriptionMatcherDelete
export def "admin-relay-subscriptions-matchers relaySubscriptionMatcherDelete" [
  id: string
  matcher_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/relay_subscriptions/($id)/matchers/($matcher_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a relay matcher on a relay subscription.
#
# PUT /api/v1/admin/relay_subscriptions/{id}/matchers/{matcher_id}
# operationId: relaySubscriptionMatcherPut
export def "admin-relay-subscriptions-matchers relaySubscriptionMatcherPut" [
  id: string
  matcher_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyword: string # The text to be matched.
  --whole-word: oneof<nothing, bool> # Matcher should consider word boundaries.
  --exclude: oneof<nothing, bool> # Matcher should cause matched posts to be excluded from relaying rather than included.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/relay_subscriptions/($id)/matchers/($matcher_id)")
  let body = {keyword: $keyword, whole_word: $whole_word, exclude: $exclude} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View user moderation reports.
#
# GET /api/v1/admin/reports
# operationId: adminReports
export def "admin-reports adminReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resolved: oneof<nothing, bool> # If present, resolved reports will be returned. If not present, unresolved reports will be returned.
  --unresolved: oneof<nothing, bool> # If present, unresolved reports will always be returned. If not present, unresolved reports will be returned only if the resolved parameter is not present. Can be used with `resolved` to return both resolved and unresolved reports in the same query.
  --account-id: string # Return only reports created by the given account id.
  --target-account-id: string # Return only reports that target the given account id.
  --max-id: string # Return only reports *OLDER* than the given max ID (for paging downwards). The report with the specified ID will not be included in the response.
  --since-id: string # Return only reports *NEWER* than the given since ID. The report with the specified ID will not be included in the response.
  --min-id: string # Return only reports immediately *NEWER* than the given min ID (for paging upwards). The report with the specified ID will not be included in the response.
  --limit: int # Number of reports to return. (default: 20)
]: nothing -> table<account: record<account: record, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list, locale: string, role: record, silenced: bool, suspended: bool, username: string>, action_taken: bool, action_taken_at: string, action_taken_by_account: record<account: record, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list, locale: string, role: record, silenced: bool, suspended: bool, username: string>, action_taken_comment: string, assigned_account: record<account: record, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list, locale: string, role: record, silenced: bool, suspended: bool, username: string>, category: string, comment: string, created_at: string, forwarded: bool, id: string, rules: list<record>, statuses: list<record>, target_account: record<account: record, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list, locale: string, role: record, silenced: bool, suspended: bool, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolved" $resolved "scalar") (serialize-qp "unresolved" $unresolved "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "target_account_id" $target_account_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View user moderation report with the given id.
#
# GET /api/v1/admin/reports/{id}
# operationId: adminReportGet
export def "admin-reports adminReportGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, action_taken: bool, action_taken_at: string, action_taken_by_account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, action_taken_comment: string, assigned_account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, category: string, comment: string, created_at: string, forwarded: bool, id: string, rules: table<id: string, text: string>, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/reports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark a report as resolved.
#
# POST /api/v1/admin/reports/{id}/resolve
# operationId: adminReportResolve
export def "admin-reports-resolve adminReportResolve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action-taken-comment: string # Optional admin comment on the action taken in response to this report. Useful for providing an explanation about what action was taken (if any) before the report was marked as resolved. This will be visible to the user that created the report! Sample: The reported account was suspended.
]: any -> record<account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, action_taken: bool, action_taken_at: string, action_taken_by_account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, action_taken_comment: string, assigned_account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, category: string, comment: string, created_at: string, forwarded: bool, id: string, rules: table<id: string, text: string>, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/admin/reports/($id)/resolve")
  let body = {action_taken_comment: $action_taken_comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get an array of currently active announcements.
#
# GET /api/v1/announcements
# operationId: announcementsGet
export def "announcements announcementsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/announcements")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of applications that are managed by the requester.
#
# GET /api/v1/apps
# operationId: appsGet
export def "apps appsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only items *OLDER* than the given max item ID. The item with the specified ID will not be included in the response.
  --since-id: string # Return only items *newer* than the given since item ID. The item with the specified ID will not be included in the response.
  --min-id: string # Return only items *immediately newer* than the given since item ID. The item with the specified ID will not be included in the response.
  --limit: int # Number of items to return. (default: 20)
]: nothing -> table<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a new application on this instance.
#
# POST /api/v1/apps
# operationId: appCreate
export def "apps appCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_name: string # The name of the application.
  --redirect-uris: string # Single redirect URI or newline-separated list of redirect URIs (optional).  To display the authorization code to the user instead of redirecting to a web page, use `urn:ietf:wg:oauth:2.0:oob` in this parameter.  If no redirect URIs are provided, defaults to `urn:ietf:wg:oauth:2.0:oob`.
  --scopes: string # Space separated list of scopes (optional).  If no scopes are provided, defaults to `read`.
  --website: string # A URL to the web page of the app (optional).
]: any -> record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/apps")
  let body = {client_name: $client_name, redirect_uris: $redirect_uris, scopes: $scopes, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a single application managed by the requester.
#
# DELETE /api/v1/apps/{id}
# operationId: appDelete
export def "apps appDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single application managed by the requester.
#
# GET /api/v1/apps/{id}
# operationId: appGet
export def "apps appGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/apps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of accounts that requesting account has blocked.
#
# GET /api/v1/blocks
# operationId: blocksGet
export def "blocks blocksGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only blocked accounts *OLDER* than the given max ID. The blocked account with the specified ID will not be included in the response. NOTE: the ID is of the internal block, NOT any of the returned accounts.
  --since-id: string # Return only blocked accounts *NEWER* than the given since ID. The blocked account with the specified ID will not be included in the response. NOTE: the ID is of the internal block, NOT any of the returned accounts.
  --min-id: string # Return only blocked accounts *IMMEDIATELY NEWER* than the given min ID. The blocked account with the specified ID will not be included in the response. NOTE: the ID is of the internal block, NOT any of the returned accounts.
  --limit: int # Number of blocked accounts to return. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of statuses bookmarked in the instance
#
# GET /api/v1/bookmarks
# operationId: bookmarksGet
export def "bookmarks bookmarksGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of statuses to return. (default: 30)
  --max-id: string # Return only bookmarked statuses *OLDER* than the given bookmark ID. The status with the corresponding bookmark ID will not be included in the response.
  --min-id: string # Return only bookmarked statuses *NEWER* than the given bookmark ID. The status with the corresponding bookmark ID will not be included in the response.
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/bookmarks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark a conversation with the given ID as read.
#
# POST /api/v1/conversation/{id}/read
# operationId: conversationRead
export def "conversation-read conversationRead" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accounts: table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, id: string, last_status: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, unread: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/conversation/($id)/read")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of (direct message) conversations that requesting account is involved in.
#
# GET /api/v1/conversations
# operationId: conversationsGet
export def "conversations conversationsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only conversations with last statuses *OLDER* than the given max ID. The conversation with the specified ID will not be included in the response. NOTE: The ID is a status ID. Use the Link header for pagination.
  --since-id: string # Return only conversations with last statuses *NEWER* than the given since ID. The conversation with the specified ID will not be included in the response. NOTE: The ID is a status ID. Use the Link header for pagination.
  --min-id: string # Return only conversations with last statuses *IMMEDIATELY NEWER* than the given min ID. The conversation with the specified ID will not be included in the response. NOTE: The ID is a status ID. Use the Link header for pagination.
  --limit: int # Number of conversations to return. (default: 40)
]: nothing -> table<accounts: list<record>, id: string, last_status: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, unread: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a single conversation with the given ID.
#
# DELETE /api/v1/conversations/{id}
# operationId: conversationDelete
export def "conversations conversationDelete" [
  id: string
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
  let full_url = (build-url $base $"/api/v1/conversations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of custom emojis available on the instance.
#
# GET /api/v1/custom_emojis
# operationId: customEmojisGet
export def "custom-emojis customEmojisGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/custom_emojis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform a GET to the specified ActivityPub URL and return detailed debugging information.
#
# GET /api/v1/debug/apurl
# operationId: apURL
export def "debug-apurl apURL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # The URL / ActivityPub ID to dereference. This should be a full URL, including protocol. Eg., `https://example.org/users/someone`
]: nothing -> record<request_headers: record, request_url: string, response_body: string, response_code: int, response_headers: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/debug/apurl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sweep/clear all in-memory caches.
#
# POST /api/v1/debug/caches/clear
# operationId: clearCaches
export def "debug-caches-clear clearCaches" [
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
  let full_url = (build-url $base "/api/v1/debug/caches/clear")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View status debug visibility information.
#
# GET /api/v1/debug/status/visibility
# operationId: statusVisibility
export def "debug-status-visibility statusVisibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uri: string # Target status URL or URI.
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uri" $uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/debug/status/visibility" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of accounts **on this instance** that have marked themselves as being "discoverable" in the directory.
#
# GET /api/v1/directory
# operationId: directoryGet
export def "directory directoryGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Skip the first n results. If offset is provided, other paging parameters will be ignored.
  --max-id: string # Return only items after than the given max ID. The item with the specified ID will not be included in the response. Parameter ignored if offset is specified.
  --since-id: string # Return only items before the given since ID. The item with the specified ID will not be included in the response. Parameter ignored if offset is specified.
  --min-id: string # Return only items *IMMEDIATELY BEFORE* the given min ID. The item with the specified ID will not be included in the response. Parameter ignored if offset is specified.
  --limit: int # Number of accounts to return. (default: 40)
  --order: string # Use 'active' to sort by most recently posted statuses (default), or 'new' to sort by most recently created profiles.
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/directory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a CSV file of accounts that you block.
#
# GET /api/v1/exports/blocks.csv
# operationId: exportBlocks
export def "exports-blockscsv exportBlocks" [
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
  let full_url = (build-url $base "/api/v1/exports/blocks.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a CSV file of accounts that follow you.
#
# GET /api/v1/exports/followers.csv
# operationId: exportFollowers
export def "exports-followerscsv exportFollowers" [
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
  let full_url = (build-url $base "/api/v1/exports/followers.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a CSV file of accounts that you follow.
#
# GET /api/v1/exports/following.csv
# operationId: exportFollowing
export def "exports-followingcsv exportFollowing" [
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
  let full_url = (build-url $base "/api/v1/exports/following.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a CSV file of lists created by you.
#
# GET /api/v1/exports/lists.csv
# operationId: exportLists
export def "exports-listscsv exportLists" [
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
  let full_url = (build-url $base "/api/v1/exports/lists.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a CSV file of accounts that you mute.
#
# GET /api/v1/exports/mutes.csv
# operationId: exportMutes
export def "exports-mutescsv exportMutes" [
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
  let full_url = (build-url $base "/api/v1/exports/mutes.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns informational stats on the number of items that can be exported for requesting account.
#
# GET /api/v1/exports/stats
# operationId: exportStats
export def "exports-stats exportStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blocks_count: int, followers_count: int, following_count: int, lists_count: int, media_storage: string, mutes_count: int, statuses_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/exports/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of statuses that the requesting account has favourited.
#
# GET /api/v1/favourites
# operationId: favouritesGet
export def "favourites favouritesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of statuses to return. (default: 20)
  --max-id: string # Return only favourited statuses *OLDER* than the given favourite ID. The status with the corresponding fave ID will not be included in the response.
  --min-id: string # Return only favourited statuses *NEWER* than the given favourite ID. The status with the corresponding fave ID will not be included in the response.
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/favourites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of all hashtags that you currently have featured on your profile.
#
# GET /api/v1/featured_tags
# operationId: getFeaturedTags
export def "featured-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/featured_tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all filters for the authenticated account.
#
# GET /api/v1/filters
# operationId: filtersV1Get
export def "filters filtersV1Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/filters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a single filter.
#
# POST /api/v1/filters
# operationId: filterV1Post
export def "filters filterV1Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phrase: string # The text to be filtered.  Sample: fnord
  context: list # The contexts in which the filter should be applied.  Sample: home, public
  --expires-in: float # Number of seconds from now that the filter should expire. If omitted, filter never expires.  Sample: 86400
  --irreversible: oneof<nothing, bool> # Should matching entities be removed from the user's timelines/views, instead of hidden? Not supported yet.  Sample: false
  --whole-word: oneof<nothing, bool> # Should the filter consider word boundaries?  Sample: true
]: any -> record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/filters")
  let body = {phrase: $phrase, context[]: $context, expires_in: $expires_in, irreversible: $irreversible, whole_word: $whole_word} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a single filter with the given ID.
#
# DELETE /api/v1/filters/{id}
# operationId: filterV1Delete
export def "filters filterV1Delete" [
  id: string
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
  let full_url = (build-url $base $"/api/v1/filters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single filter with the given ID.
#
# GET /api/v1/filters/{id}
# operationId: filterV1Get
export def "filters filterV1Get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/filters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single filter with the given ID.
#
# PUT /api/v1/filters/{id}
# operationId: filterV1Put
export def "filters filterV1Put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phrase: string # The text to be filtered.  Sample: fnord
  context: list # The contexts in which the filter should be applied.  Sample: home, public
  --expires-in: float # Number of seconds from now that the filter should expire. If omitted, filter never expires.  Sample: 86400
  --irreversible: oneof<nothing, bool> # Should matching entities be removed from the user's timelines/views, instead of hidden? Not supported yet.  Sample: false
  --whole-word: oneof<nothing, bool> # Should the filter consider word boundaries?  Sample: true
]: any -> record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/filters/($id)")
  let body = {phrase: $phrase, context[]: $context, expires_in: $expires_in, irreversible: $irreversible, whole_word: $whole_word} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get an array of accounts that have requested to follow you.
#
# GET /api/v1/follow_requests
# operationId: getFollowRequests
export def "follow-requests get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only follow requesting accounts *OLDER* than the given max ID. The follow requester with the specified ID will not be included in the response. NOTE: the ID is of the internal follow request, NOT any of the returned accounts.
  --since-id: string # Return only follow requesting accounts *NEWER* than the given since ID. The follow requester with the specified ID will not be included in the response. NOTE: the ID is of the internal follow request, NOT any of the returned accounts.
  --min-id: string # Return only follow requesting accounts *IMMEDIATELY NEWER* than the given min ID. The follow requester with the specified ID will not be included in the response. NOTE: the ID is of the internal follow request, NOT any of the returned accounts.
  --limit: int # Number of follow requesting accounts to return. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/follow_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept/authorize follow request from the given account ID.
#
# POST /api/v1/follow_requests/{account_id}/authorize
# operationId: authorizeFollowRequest
export def "follow-requests-authorize authorizeFollowRequest" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/follow_requests/($account_id)/authorize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject/deny follow request from the given account ID.
#
# POST /api/v1/follow_requests/{account_id}/reject
# operationId: rejectFollowRequest
export def "follow-requests-reject rejectFollowRequest" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, requested_by: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/follow_requests/($account_id)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of accounts that you have requested to follow.
#
# GET /api/v1/follow_requests/outgoing
# operationId: getOutgoingFollowRequests
export def "follow-requests-outgoing get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only follow requested accounts *OLDER* than the given max ID. The follow requestee with the specified ID will not be included in the response. NOTE: the ID is of the internal follow request, NOT any of the returned accounts.
  --since-id: string # Return only follow requested accounts *NEWER* than the given since ID. The follow requestee with the specified ID will not be included in the response. NOTE: the ID is of the internal follow request, NOT any of the returned accounts.
  --min-id: string # Return only follow requested accounts *IMMEDIATELY NEWER* than the given min ID. The follow requestee with the specified ID will not be included in the response. NOTE: the ID is of the internal follow request, NOT any of the returned accounts.
  --limit: int # Number of follow requested accounts to return. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/follow_requests/outgoing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of all hashtags that you currently follow.
#
# GET /api/v1/followed_tags
# operationId: getFollowedTags
export def "followed-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only followed tags *OLDER* than the given max ID. The followed tag with the specified ID will not be included in the response. NOTE: the ID is of the internal followed tag, NOT a tag name.
  --since-id: string # Return only followed tags *NEWER* than the given since ID. The followed tag with the specified ID will not be included in the response. NOTE: the ID is of the internal followed tag, NOT a tag name.
  --min-id: string # Return only followed tags *IMMEDIATELY NEWER* than the given min ID. The followed tag with the specified ID will not be included in the response. NOTE: the ID is of the internal followed tag, NOT a tag name.
  --limit: int # Number of followed tags to return. (default: 100)
]: nothing -> table<following: bool, history: list<any>, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/followed_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload some CSV-formatted data to your account.
#
# POST /api/v1/import
# operationId: importData
export def "import importData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: path # The CSV data file to upload.
  type: string # Type of entries contained in the data file: - `following` - accounts to follow. - `blocks` - accounts to block. - `mutes` - accounts to mute.
  --mode: string # Mode to use when creating entries from the data file: - `merge` to merge entries in file with existing entries. - `overwrite` to replace existing entries with entries in file.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/import")
  let body = {data: $data, type: $type, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($data | is-not-empty) { $body | upsert data (open -r $data) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# View instance information.
#
# GET /api/v1/instance
# operationId: instanceGetV1
export def "instance instanceGetV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_domain: string, approval_required: bool, configuration: record<accounts: record<allow_custom_css: bool, max_featured_tags: int, max_profile_fields: int>, emojis: record<emoji_size_limit: int>, media_attachments: record<description_limit: int, description_minimum: int, image_matrix_limit: int, image_size_limit: int, supported_mime_types: list, video_frame_rate_limit: int, video_matrix_limit: int, video_size_limit: int>, oidc_enabled: bool, polls: record<max_characters_per_option: int, max_expiration: int, max_options: int, min_expiration: int>, statuses: record<characters_reserved_per_url: int, max_characters: int, max_media_attachments: int, supported_mime_types: list>>, contact_account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, custom_css: string, debug: bool, description: string, description_text: string, email: string, invites_enabled: bool, languages: list<string>, max_toot_chars: int, registrations: bool, rules: table<id: string, text: string>, short_description: string, short_description_text: string, stats: record, terms: string, terms_text: string, thumbnail: string, thumbnail_description: string, thumbnail_static: string, thumbnail_static_type: string, thumbnail_type: string, title: string, uri: string, urls: record<streaming_api: string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update your instance information and/or upload a new avatar/header for the instance.
#
# PATCH /api/v1/instance
# operationId: instanceUpdate
export def "instance instanceUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title to use for the instance.
  --contact-username: string # Username of the contact account. This must be the username of an instance admin.
  --contact-email: string # Email address to use as the instance contact.
  --short-description: string # Short description of the instance.
  --description: string # Longer description of the instance.
  --terms: string # Terms and conditions of the instance.
  --thumbnail: path # Thumbnail image to use for the instance.
  --thumbnail-description: string # Image description of the submitted instance thumbnail.
  --header: path # Header image to use for the instance.
]: any -> record<account_domain: string, approval_required: bool, configuration: record<accounts: record<allow_custom_css: bool, max_featured_tags: int, max_profile_fields: int>, emojis: record<emoji_size_limit: int>, media_attachments: record<description_limit: int, description_minimum: int, image_matrix_limit: int, image_size_limit: int, supported_mime_types: list, video_frame_rate_limit: int, video_matrix_limit: int, video_size_limit: int>, oidc_enabled: bool, polls: record<max_characters_per_option: int, max_expiration: int, max_options: int, min_expiration: int>, statuses: record<characters_reserved_per_url: int, max_characters: int, max_media_attachments: int, supported_mime_types: list>>, contact_account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, custom_css: string, debug: bool, description: string, description_text: string, email: string, invites_enabled: bool, languages: list<string>, max_toot_chars: int, registrations: bool, rules: table<id: string, text: string>, short_description: string, short_description_text: string, stats: record, terms: string, terms_text: string, thumbnail: string, thumbnail_description: string, thumbnail_static: string, thumbnail_static_type: string, thumbnail_type: string, title: string, uri: string, urls: record<streaming_api: string>, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance")
  let body = {title: $title, contact_username: $contact_username, contact_email: $contact_email, short_description: $short_description, description: $description, terms: $terms, thumbnail: $thumbnail, thumbnail_description: $thumbnail_description, header: $header} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($thumbnail | is-not-empty) { $body | upsert thumbnail (open -r $thumbnail) } else { $body }
  let body = if ($header | is-not-empty) { $body | upsert header (open -r $header) } else { $body }
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List explicitly allowed domains.
#
# GET /api/v1/instance/domain_allows
# operationId: instanceDomainAllowsGet
export def "instance-domain-allows instanceDomainAllowsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<comment: string, domain: string, public_comment: string, severity: string, silenced_at: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/domain_allows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List blocked domains.
#
# GET /api/v1/instance/domain_blocks
# operationId: instanceDomainBlocksGet
export def "instance-domain-blocks instanceDomainBlocksGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<comment: string, domain: string, public_comment: string, severity: string, silenced_at: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/domain_blocks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List peer domains.
#
# GET /api/v1/instance/peers
# operationId: instancePeersGet
export def "instance-peers instancePeersGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Comma-separated list of filters to apply to results. Recognized filters are:   - `open` -- include known domains that are not in the domain blocklist   - `allowed` -- include domains that are in the domain allowlist   - `blocked` -- include domains that are in the domain blocklist   - `suspended` -- DEPRECATED! Use `blocked` instead. Same as `blocked`: include domains that are in the domain blocklist;  If filter is `open`, only domains that aren't in the blocklist will be shown.  If filter is `blocked`, only domains that *are* in the blocklist will be shown.  If filter is `allowed`, only domains that are in the allowlist will be shown.  If filter is `open,blocked`, then blocked domains and known domains not on the blocklist will be shown.  If filter is `open,allowed`, then allowed domains and known domains not on the blocklist will be shown.  If filter is an empty string or not set, then `open` will be assumed as the default. (default: flat)
  --flat: oneof<nothing, bool> # If true, a "flat" array of strings will be returned corresponding to just domain names. (default: false)
]: nothing -> table<comment: string, domain: string, public_comment: string, severity: string, silenced_at: string, suspended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "flat" $flat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/instance/peers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View instance rules (public).
#
# GET /api/v1/instance/rules
# operationId: rules
export def "instance-rules rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default interaction policies for new statuses created by you.
#
# GET /api/v1/interaction_policies/defaults
# operationId: policiesDefaultsGet
export def "interaction-policies-defaults policiesDefaultsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<direct: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, private: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, public: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, unlisted: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/interaction_policies/defaults")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update default interaction policies per visibility level for new statuses created by you.
#
# PATCH /api/v1/interaction_policies/defaults
# operationId: policiesDefaultsUpdate
export def "interaction-policies-defaults policiesDefaultsUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --publiccan-favouriteautomatic-approval0: string # Nth entry for public.can_favourite.automatic_approval.
  --publiccan-favouritemanual-approval0: string # Nth entry for public.can_favourite.manual_approval.
  --publiccan-replyautomatic-approval0: string # Nth entry for public.can_reply.automatic_approval.
  --publiccan-replymanual-approval0: string # Nth entry for public.can_reply.manual_approval.
  --publiccan-reblogautomatic-approval0: string # Nth entry for public.can_reblog.automatic_approval.
  --publiccan-reblogmanual-approval0: string # Nth entry for public.can_reblog.manual_approval.
  --unlistedcan-favouriteautomatic-approval0: string # Nth entry for unlisted.can_favourite.automatic_approval.
  --unlistedcan-favouritemanual-approval0: string # Nth entry for unlisted.can_favourite.manual_approval.
  --unlistedcan-replyautomatic-approval0: string # Nth entry for unlisted.can_reply.automatic_approval.
  --unlistedcan-replymanual-approval0: string # Nth entry for unlisted.can_reply.manual_approval.
  --unlistedcan-reblogautomatic-approval0: string # Nth entry for unlisted.can_reblog.automatic_approval.
  --unlistedcan-reblogmanual-approval0: string # Nth entry for unlisted.can_reblog.manual_approval.
  --privatecan-favouriteautomatic-approval0: string # Nth entry for private.can_favourite.automatic_approval.
  --privatecan-favouritemanual-approval0: string # Nth entry for private.can_favourite.manual_approval.
  --privatecan-replyautomatic-approval0: string # Nth entry for private.can_reply.automatic_approval.
  --privatecan-replymanual-approval0: string # Nth entry for private.can_reply.manual_approval.
  --privatecan-reblogautomatic-approval0: string # Nth entry for private.can_reblog.automatic_approval.
  --privatecan-reblogmanual-approval0: string # Nth entry for private.can_reblog.manual_approval.
  --directcan-favouriteautomatic-approval0: string # Nth entry for direct.can_favourite.automatic_approval.
  --directcan-favouritemanual-approval0: string # Nth entry for direct.can_favourite.manual_approval.
  --directcan-replyautomatic-approval0: string # Nth entry for direct.can_reply.automatic_approval.
  --directcan-replymanual-approval0: string # Nth entry for direct.can_reply.manual_approval.
  --directcan-reblogautomatic-approval0: string # Nth entry for direct.can_reblog.automatic_approval.
  --directcan-reblogmanual-approval0: string # Nth entry for direct.can_reblog.manual_approval.
]: any -> record<direct: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, private: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, public: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, unlisted: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/interaction_policies/defaults")
  let body = {public[can_favourite][automatic_approval][0]: $publiccan_favouriteautomatic_approval0, public[can_favourite][manual_approval][0]: $publiccan_favouritemanual_approval0, public[can_reply][automatic_approval][0]: $publiccan_replyautomatic_approval0, public[can_reply][manual_approval][0]: $publiccan_replymanual_approval0, public[can_reblog][automatic_approval][0]: $publiccan_reblogautomatic_approval0, public[can_reblog][manual_approval][0]: $publiccan_reblogmanual_approval0, unlisted[can_favourite][automatic_approval][0]: $unlistedcan_favouriteautomatic_approval0, unlisted[can_favourite][manual_approval][0]: $unlistedcan_favouritemanual_approval0, unlisted[can_reply][automatic_approval][0]: $unlistedcan_replyautomatic_approval0, unlisted[can_reply][manual_approval][0]: $unlistedcan_replymanual_approval0, unlisted[can_reblog][automatic_approval][0]: $unlistedcan_reblogautomatic_approval0, unlisted[can_reblog][manual_approval][0]: $unlistedcan_reblogmanual_approval0, private[can_favourite][automatic_approval][0]: $privatecan_favouriteautomatic_approval0, private[can_favourite][manual_approval][0]: $privatecan_favouritemanual_approval0, private[can_reply][automatic_approval][0]: $privatecan_replyautomatic_approval0, private[can_reply][manual_approval][0]: $privatecan_replymanual_approval0, private[can_reblog][automatic_approval][0]: $privatecan_reblogautomatic_approval0, private[can_reblog][manual_approval][0]: $privatecan_reblogmanual_approval0, direct[can_favourite][automatic_approval][0]: $directcan_favouriteautomatic_approval0, direct[can_favourite][manual_approval][0]: $directcan_favouritemanual_approval0, direct[can_reply][automatic_approval][0]: $directcan_replyautomatic_approval0, direct[can_reply][manual_approval][0]: $directcan_replymanual_approval0, direct[can_reblog][automatic_approval][0]: $directcan_reblogautomatic_approval0, direct[can_reblog][manual_approval][0]: $directcan_reblogmanual_approval0} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get an array of interactions requested on your statuses by other accounts, and pending your approval.
#
# GET /api/v1/interaction_requests
# operationId: getInteractionRequests
export def "interaction-requests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-id: string # If set, then only interactions targeting the given status_id will be included in the results.
  --favourites: oneof<nothing, bool> # If true or not set, pending favourites will be included in the results. At least one of favourites, replies, and reblogs must be true. (default: true)
  --replies: oneof<nothing, bool> # If true or not set, pending replies will be included in the results. At least one of favourites, replies, and reblogs must be true. (default: true)
  --reblogs: oneof<nothing, bool> # If true or not set, pending reblogs will be included in the results. At least one of favourites, replies, and reblogs must be true. (default: true)
  --max-id: string # Return only interaction requests *OLDER* than the given max ID. The interaction with the specified ID will not be included in the response.
  --since-id: string # Return only interaction requests *NEWER* than the given since ID. The interaction with the specified ID will not be included in the response.
  --min-id: string # Return only interaction requests *IMMEDIATELY NEWER* than the given min ID. The interaction with the specified ID will not be included in the response.
  --limit: int # Number of interaction requests to return. (default: 40)
]: nothing -> table<accepted_at: string, account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, created_at: string, id: string, rejected_at: string, reply: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, status: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status_id" $status_id "scalar") (serialize-qp "favourites" $favourites "scalar") (serialize-qp "replies" $replies "scalar") (serialize-qp "reblogs" $reblogs "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/interaction_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get interaction request with the given ID.
#
# GET /api/v1/interaction_requests/{id}
# operationId: getInteractionRequest
export def "interaction-requests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accepted_at: string, account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, created_at: string, id: string, rejected_at: string, reply: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, status: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/interaction_requests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept/authorize/approve an interaction request with the given ID.
#
# POST /api/v1/interaction_requests/{id}/authorize
# operationId: authorizeInteractionRequest
export def "interaction-requests-authorize authorizeInteractionRequest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accepted_at: string, account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, created_at: string, id: string, rejected_at: string, reply: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, status: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/interaction_requests/($id)/authorize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject an interaction request with the given ID.
#
# POST /api/v1/interaction_requests/{id}/reject
# operationId: rejectInteractionRequest
export def "interaction-requests-reject rejectInteractionRequest" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accepted_at: string, account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, created_at: string, id: string, rejected_at: string, reply: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, status: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/interaction_requests/($id)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all lists owned by authorized user.
#
# GET /api/v1/lists
# operationId: lists
export def "lists lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<exclusive: bool, id: string, replies_policy: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new list.
#
# POST /api/v1/lists
# operationId: listCreate
export def "lists listCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Title of this list. Sample: Cool People
  --replies-policy: string@replies-policy-completer # RepliesPolicy for this list. followed = Show replies to any followed user list = Show replies to members of the list none = Show replies to no one Sample: list
  --exclusive: oneof<nothing, bool> # Hide posts from members of this list from your home timeline.
]: any -> record<exclusive: bool, id: string, replies_policy: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/lists")
  let body = {title: $title, replies_policy: $replies_policy, exclusive: $exclusive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a single list with the given ID.
#
# DELETE /api/v1/lists/{id}
# operationId: listDelete
export def "lists listDelete" [
  id: string
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
  let full_url = (build-url $base $"/api/v1/lists/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single list with the given ID.
#
# GET /api/v1/lists/{id}
# operationId: list
export def "lists list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<exclusive: bool, id: string, replies_policy: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/lists/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing list.
#
# PUT /api/v1/lists/{id}
# operationId: listUpdate
export def "lists listUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of this list. Sample: Cool People
  --replies-policy: string@replies-policy-completer # RepliesPolicy for this list. followed = Show replies to any followed user list = Show replies to members of the list none = Show replies to no one Sample: list
  --exclusive: oneof<nothing, bool> # Hide posts from members of this list from your home timeline.
]: any -> record<exclusive: bool, id: string, replies_policy: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/lists/($id)")
  let body = {title: $title, replies_policy: $replies_policy, exclusive: $exclusive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove one or more accounts from the given list.
#
# DELETE /api/v1/lists/{id}/accounts
# operationId: removeListAccounts
export def "lists-accounts removeListAccounts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_ids: list # Array of accountIDs to modify. Each accountID must correspond to an account that the requesting account follows.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/lists/($id)/accounts")
  let body = {account_ids[]: $account_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Page through accounts in this list.
#
# GET /api/v1/lists/{id}/accounts
# operationId: listAccounts
export def "lists-accounts listAccounts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only list entries *OLDER* than the given max ID. The account from the list entry with the specified ID will not be included in the response.
  --since-id: string # Return only list entries *NEWER* than the given since ID. The account from the list entry with the specified ID will not be included in the response.
  --min-id: string # Return only list entries *IMMEDIATELY NEWER* than the given min ID. The account from the list entry with the specified ID will not be included in the response.
  --limit: int # Number of accounts to return. If set to 0 explicitly, all accounts in the list will be returned, and pagination headers will not be used. This is a workaround for Mastodon API peculiarities: https://docs.joinmastodon.org/methods/lists/#query-parameters. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/lists/($id)/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add one or more accounts to the given list.
#
# POST /api/v1/lists/{id}/accounts
# operationId: addListAccounts
export def "lists-accounts addListAccounts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_ids: list # Array of accountIDs to modify. Each accountID must correspond to an account that the requesting account follows.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/lists/($id)/accounts")
  let body = {account_ids[]: $account_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get timeline markers by name
#
# GET /api/v1/markers
# operationId: markersGet
export def "markers markersGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeline: list # Timelines to retrieve.
]: nothing -> record<home: record<last_read_id: string, updated_at: string, version: int>, notifications: record<last_read_id: string, updated_at: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeline" $timeline "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/markers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update timeline markers by name
#
# POST /api/v1/markers
# operationId: markersPost
export def "markers markersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --homelast-read-id: string # Last status ID read on the home timeline.
  --notificationslast-read-id: string # Last notification ID read on the notifications timeline.
]: any -> record<home: record<last_read_id: string, updated_at: string, version: int>, notifications: record<last_read_id: string, updated_at: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/markers")
  let body = {home[last_read_id]: $homelast_read_id, notifications[last_read_id]: $notificationslast_read_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a media attachment that you own.
#
# GET /api/v1/media/{id}
# operationId: mediaGet
export def "media mediaGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<blurhash: string, description: string, error: string, id: string, meta: record<focus: record<x: float, y: float>, original: record<aspect: float, bitrate: int, duration: float, frame_rate: string, height: int, size: string, width: int>, small: record<aspect: float, bitrate: int, duration: float, frame_rate: string, height: int, size: string, width: int>>, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/media/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a media attachment.
#
# PUT /api/v1/media/{id}
# operationId: mediaUpdate
export def "media mediaUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Image or media description to use as alt-text on the attachment. This is very useful for users of screenreaders! May or may not be required, depending on your instance settings.
  --focus: string # Focus of the media file. If present, it should be in the form of two comma-separated floats between -1 and 1. For example: `-0.5,0.25`.
]: any -> record<blurhash: string, description: string, error: string, id: string, meta: record<focus: record<x: float, y: float>, original: record<aspect: float, bitrate: int, duration: float, frame_rate: string, height: int, size: string, width: int>, small: record<aspect: float, bitrate: int, duration: float, frame_rate: string, height: int, size: string, width: int>>, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/media/($id)")
  let body = {description: $description, focus: $focus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get an array of accounts that requesting account has muted.
#
# GET /api/v1/mutes
# operationId: mutesGet
export def "mutes mutesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only muted accounts *OLDER* than the given max ID. The muted account with the specified ID will not be included in the response. NOTE: the ID is of the internal mute, NOT any of the returned accounts.
  --since-id: string # Return only muted accounts *NEWER* than the given since ID. The muted account with the specified ID will not be included in the response. NOTE: the ID is of the internal mute, NOT any of the returned accounts.
  --min-id: string # Return only muted accounts *IMMEDIATELY NEWER* than the given min ID. The muted account with the specified ID will not be included in the response. NOTE: the ID is of the internal mute, NOT any of the returned accounts.
  --limit: int # Number of muted accounts to return. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, mute_expires_at: string, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/mutes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single notification with the given ID.
#
# GET /api/v1/notification/{id}
# operationId: notification
export def "notification notification" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, created_at: string, id: string, status: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get notifications for currently authorized user.
#
# GET /api/v1/notifications
# operationId: notifications
export def "notifications notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only notifications *OLDER* than the given max notification ID. The notification with the specified ID will not be included in the response.
  --since-id: string # Return only notifications *newer* than the given since notification ID. The notification with the specified ID will not be included in the response.
  --min-id: string # Return only notifications *immediately newer* than the given since notification ID. The notification with the specified ID will not be included in the response.
  --limit: int # Number of notifications to return. (default: 20)
  --types: list # Types of notifications to include. If not provided, all notification types will be included.
  --exclude-types: list # Types of notifications to exclude.
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, created_at: string, id: string, status: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "types[]" $types "csv") (serialize-qp "exclude_types[]" $exclude_types "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clear/delete all notifications for currently authorized user.
#
# POST /api/v1/notifications/clear
# operationId: clearNotifications
export def "notifications-clear clearNotifications" [
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
  let full_url = (build-url $base "/api/v1/notifications/clear")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View poll with given ID.
#
# GET /api/v1/polls/{id}
# operationId: poll
export def "polls poll" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: table<title: string, votes_count: int>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/polls/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Vote with choices in the given poll.
#
# POST /api/v1/polls/{id}/votes
# operationId: pollVote
export def "polls-votes pollVote" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  choices: list # Poll choice indices on which to vote.
]: any -> record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: table<title: string, votes_count: int>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/polls/($id)/votes")
  let body = {choices: $choices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Return an object of user preferences.
#
# GET /api/v1/preferences
# operationId: preferencesGet
export def "preferences preferencesGet" [
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
  let full_url = (build-url $base "/api/v1/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the authenticated account's avatar.
#
# DELETE /api/v1/profile/avatar
# operationId: accountAvatarDelete
export def "profile-avatar accountAvatarDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, enable_rss: bool, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: table<color: string, id: string, name: string>, source: record<also_known_as_uris: list<string>, fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/profile/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the authenticated account's header.
#
# DELETE /api/v1/profile/header
# operationId: accountHeaderDelete
export def "profile-header accountHeaderDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, enable_rss: bool, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: table<color: string, id: string, name: string>, source: record<also_known_as_uris: list<string>, fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/profile/header")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the Web Push subscription associated with the current auth token.
#
# DELETE /api/v1/push/subscription
# operationId: pushSubscriptionDelete
export def "push-subscription pushSubscriptionDelete" [
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
  let full_url = (build-url $base "/api/v1/push/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the push subscription for the current access token.
#
# GET /api/v1/push/subscription
# operationId: pushSubscriptionGet
export def "push-subscription pushSubscriptionGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alerts: record<admin_report: bool, admin_sign_up: bool, favourite: bool, follow: bool, follow_request: bool, mention: bool, pending_favourite: bool, pending_reblog: bool, pending_reply: bool, poll: bool, reblog: bool, status: bool, update: bool>, endpoint: string, id: string, policy: string, server_key: string, standard: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Web Push subscription for the current access token, or replace the existing one.
#
# POST /api/v1/push/subscription
# operationId: pushSubscriptionPost
export def "push-subscription pushSubscriptionPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscriptionendpoint: string # The URL to which Web Push notifications will be sent.
  subscriptionkeysauth: string # The auth secret, a Base64 encoded string of 16 bytes of random data.
  subscriptionkeysp256dh: string # The user agent public key, a Base64 encoded string of a public key from an ECDH keypair using the prime256v1 curve.
  --dataalertsfollow: oneof<nothing, bool> # Receive a push notification when someone has followed you?
  --dataalertsfollow-request: oneof<nothing, bool> # Receive a push notification when someone has requested to follow you?
  --dataalertsfavourite: oneof<nothing, bool> # Receive a push notification when a status you created has been favourited by someone else?
  --dataalertsmention: oneof<nothing, bool> # Receive a push notification when someone else has mentioned you in a status?
  --dataalertsreblog: oneof<nothing, bool> # Receive a push notification when a status you created has been boosted by someone else?
  --dataalertspoll: oneof<nothing, bool> # Receive a push notification when a poll you voted in or created has ended?
  --dataalertsstatus: oneof<nothing, bool> # Receive a push notification when a subscribed account posts a status?
  --dataalertsupdate: oneof<nothing, bool> # Receive a push notification when a status you interacted with has been edited?
  --dataalertsadminsign-up: oneof<nothing, bool> # Receive a push notification when a new user has signed up?
  --dataalertsadminreport: oneof<nothing, bool> # Receive a push notification when a new report has been filed?
  --dataalertspendingfavourite: oneof<nothing, bool> # Receive a push notification when a fave is pending?
  --dataalertspendingreply: oneof<nothing, bool> # Receive a push notification when a reply is pending?
  --dataalertspendingreblog: oneof<nothing, bool> # Receive a push notification when a boost is pending?
  --datapolicy: string@datapolicy-completer # Which accounts to receive push notifications from.
]: any -> record<alerts: record<admin_report: bool, admin_sign_up: bool, favourite: bool, follow: bool, follow_request: bool, mention: bool, pending_favourite: bool, pending_reblog: bool, pending_reply: bool, poll: bool, reblog: bool, status: bool, update: bool>, endpoint: string, id: string, policy: string, server_key: string, standard: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push/subscription")
  let body = {subscription[endpoint]: $subscriptionendpoint, subscription[keys][auth]: $subscriptionkeysauth, subscription[keys][p256dh]: $subscriptionkeysp256dh, data[alerts][follow]: $dataalertsfollow, data[alerts][follow_request]: $dataalertsfollow_request, data[alerts][favourite]: $dataalertsfavourite, data[alerts][mention]: $dataalertsmention, data[alerts][reblog]: $dataalertsreblog, data[alerts][poll]: $dataalertspoll, data[alerts][status]: $dataalertsstatus, data[alerts][update]: $dataalertsupdate, data[alerts][admin.sign_up]: $dataalertsadminsign_up, data[alerts][admin.report]: $dataalertsadminreport, data[alerts][pending.favourite]: $dataalertspendingfavourite, data[alerts][pending.reply]: $dataalertspendingreply, data[alerts][pending.reblog]: $dataalertspendingreblog, data[policy]: $datapolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update the Web Push subscription for the current access token.
#
# PUT /api/v1/push/subscription
# operationId: pushSubscriptionPut
export def "push-subscription pushSubscriptionPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataalertsfollow: oneof<nothing, bool> # Receive a push notification when someone has followed you?
  --dataalertsfollow-request: oneof<nothing, bool> # Receive a push notification when someone has requested to follow you?
  --dataalertsfavourite: oneof<nothing, bool> # Receive a push notification when a status you created has been favourited by someone else?
  --dataalertsmention: oneof<nothing, bool> # Receive a push notification when someone else has mentioned you in a status?
  --dataalertsreblog: oneof<nothing, bool> # Receive a push notification when a status you created has been boosted by someone else?
  --dataalertspoll: oneof<nothing, bool> # Receive a push notification when a poll you voted in or created has ended?
  --dataalertsstatus: oneof<nothing, bool> # Receive a push notification when a subscribed account posts a status?
  --dataalertsupdate: oneof<nothing, bool> # Receive a push notification when a status you interacted with has been edited?
  --dataalertsadminsign-up: oneof<nothing, bool> # Receive a push notification when a new user has signed up?
  --dataalertsadminreport: oneof<nothing, bool> # Receive a push notification when a new report has been filed?
  --dataalertspendingfavourite: oneof<nothing, bool> # Receive a push notification when a fave is pending?
  --dataalertspendingreply: oneof<nothing, bool> # Receive a push notification when a reply is pending?
  --dataalertspendingreblog: oneof<nothing, bool> # Receive a push notification when a boost is pending?
  --datapolicy: string@datapolicy-completer # Which accounts to receive push notifications from.
]: any -> record<alerts: record<admin_report: bool, admin_sign_up: bool, favourite: bool, follow: bool, follow_request: bool, mention: bool, pending_favourite: bool, pending_reblog: bool, pending_reply: bool, poll: bool, reblog: bool, status: bool, update: bool>, endpoint: string, id: string, policy: string, server_key: string, standard: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push/subscription")
  let body = {data[alerts][follow]: $dataalertsfollow, data[alerts][follow_request]: $dataalertsfollow_request, data[alerts][favourite]: $dataalertsfavourite, data[alerts][mention]: $dataalertsmention, data[alerts][reblog]: $dataalertsreblog, data[alerts][poll]: $dataalertspoll, data[alerts][status]: $dataalertsstatus, data[alerts][update]: $dataalertsupdate, data[alerts][admin.sign_up]: $dataalertsadminsign_up, data[alerts][admin.report]: $dataalertsadminreport, data[alerts][pending.favourite]: $dataalertspendingfavourite, data[alerts][pending.reply]: $dataalertspendingreply, data[alerts][pending.reblog]: $dataalertspendingreblog, data[policy]: $datapolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View relay pushes.
#
# GET /api/v1/relay_pushes
# operationId: relayPushes
export def "relay-pushes relayPushes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: list<record>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/relay_pushes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new relay push targeting a remote relay actor URI.
#
# POST /api/v1/relay_pushes
# operationId: relayPushCreate
export def "relay-pushes relayPushCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  relay_actor_uri: string # The ActivityPub URI of the remote relay actor.
  --public: oneof<nothing, bool> # Push public posts. If false, never send public posts to this relay.
  --unlisted: oneof<nothing, bool> # Push unlisted posts. If false, never send unlisted posts to this relay.
  --match-by-default: oneof<nothing, bool> # Controls whether the relay push should send all non-ignored posts by default. If set true, and no "exclude"-type matchers are set on the push, then all included, non-ignored posts will be sent.
  --ignore-sensitive: oneof<nothing, bool> # Never send sensitive posts to this relay.
  --ignore-media: oneof<nothing, bool> # Never send posts with media attachments to this relay.
  --ignore-replies: oneof<nothing, bool> # Never send non-self-replies (ie., comments) to this relay.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/relay_pushes")
  let body = {relay_actor_uri: $relay_actor_uri, public: $public, unlisted: $unlisted, match_by_default: $match_by_default, ignore_sensitive: $ignore_sensitive, ignore_media: $ignore_media, ignore_replies: $ignore_replies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete relay push with the given ID.
#
# DELETE /api/v1/relay_pushes/{id}
# operationId: relayPushDelete
export def "relay-pushes relayPushDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/relay_pushes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View relay push with the given ID.
#
# GET /api/v1/relay_pushes/{id}
# operationId: relayPushGet
export def "relay-pushes relayPushGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/relay_pushes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a relay push.
#
# PUT /api/v1/relay_pushes/{id}
# operationId: relayPushUpdate
export def "relay-pushes relayPushUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --public: oneof<nothing, bool> # Push public posts. If false, never send public posts to this relay.
  --unlisted: oneof<nothing, bool> # Push unlisted posts. If false, never send unlisted posts to this relay.
  --match-by-default: oneof<nothing, bool> # Controls whether the relay push should send all non-ignored posts by default. If set true, and no "exclude"-type matchers are set on the push, then all included, non-ignored posts will be sent.
  --ignore-sensitive: oneof<nothing, bool> # Never send sensitive posts to this relay.
  --ignore-media: oneof<nothing, bool> # Never send posts with media attachments to this relay.
  --ignore-replies: oneof<nothing, bool> # Never send non-self-replies (ie., comments) to this relay.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/relay_pushes/($id)")
  let body = {public: $public, unlisted: $unlisted, match_by_default: $match_by_default, ignore_sensitive: $ignore_sensitive, ignore_media: $ignore_media, ignore_replies: $ignore_replies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add a relay matcher to a relay push.
#
# POST /api/v1/relay_pushes/{id}/matchers
# operationId: relayPushMatcherPost
export def "relay-pushes-matchers relayPushMatcherPost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyword: string # The text to be matched.
  --whole-word: oneof<nothing, bool> # Matcher should consider word boundaries.
  --exclude: oneof<nothing, bool> # Matcher should cause matched posts to be excluded from relaying rather than included.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/relay_pushes/($id)/matchers")
  let body = {keyword: $keyword, whole_word: $whole_word, exclude: $exclude} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a relay matcher from a relay push.
#
# DELETE /api/v1/relay_pushes/{id}/matchers/{matcher_id}
# operationId: relayPushMatcherDelete
export def "relay-pushes-matchers relayPushMatcherDelete" [
  id: string
  matcher_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/relay_pushes/($id)/matchers/($matcher_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a relay matcher on a relay push.
#
# PUT /api/v1/relay_pushes/{id}/matchers/{matcher_id}
# operationId: relayPushMatcherPut
export def "relay-pushes-matchers relayPushMatcherPut" [
  id: string
  matcher_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyword: string # The text to be matched.
  --whole-word: oneof<nothing, bool> # Matcher should consider word boundaries.
  --exclude: oneof<nothing, bool> # Matcher should cause matched posts to be excluded from relaying rather than included.
]: any -> record<account_id: string, approved: bool, created_at: string, id: string, ignore_media: bool, ignore_replies: bool, ignore_sensitive: bool, match_by_default: bool, matchers: table<exclude: bool, id: string, keyword: string, whole_word: bool>, public: bool, relay_actor_uri: string, unlisted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/relay_pushes/($id)/matchers/($matcher_id)")
  let body = {keyword: $keyword, whole_word: $whole_word, exclude: $exclude} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# See reports created by the requesting account.
#
# GET /api/v1/reports
# operationId: reports
export def "reports reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resolved: oneof<nothing, bool> # If set to true, only resolved reports will be returned. If false, only unresolved reports will be returned. If unset, reports will not be filtered on their resolved status.
  --target-account-id: string # Return only reports that target the given account id.
  --max-id: string # Return only reports *OLDER* than the given max ID (for paging downwards). The report with the specified ID will not be included in the response.
  --since-id: string # Return only reports *NEWER* than the given since ID. The report with the specified ID will not be included in the response.
  --min-id: string # Return only reports immediately *NEWER* than the given min ID (for paging upwards). The report with the specified ID will not be included in the response.
  --limit: int # Number of reports to return. (default: 20)
]: nothing -> table<action_taken: bool, action_taken_at: string, action_taken_comment: string, category: string, comment: string, created_at: string, forwarded: bool, id: string, rule_ids: list<string>, status_ids: list<string>, target_account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolved" $resolved "scalar") (serialize-qp "target_account_id" $target_account_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user report with the given parameters.
#
# POST /api/v1/reports
# operationId: reportCreate
export def "reports reportCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_id: string # ID of the account to report. Sample: 01GPE75FXSH2EGFBF85NXPH3KP
  --status-ids: list # IDs of statuses to attach to the report to provide additional context. Sample: ["01GPE76N4SBVRZ8K24TW51ZZQ4","01GPE76WN9JZE62EPT3Q9FRRD4"]
  --comment: string # The reason for the report. Default maximum of 1000 characters. Sample: Anti-Blackness, transphobia.
  --forward: oneof<nothing, bool> # If the account is remote, should the report be forwarded to the remote admin? Sample: true
  --category: string # Specify if the report is due to spam, violation of enumerated instance rules, or some other reason. Currently only 'other' is supported. Sample: other
  --rule-ids: list # IDs of rules on this instance which have been broken according to the reporter. Sample: ["01GPBN5YDY6JKBWE44H7YQBDCQ","01GPBN65PDWSBPWVDD0SQCFFY3"]
]: any -> record<action_taken: bool, action_taken_at: string, action_taken_comment: string, category: string, comment: string, created_at: string, forwarded: bool, id: string, rule_ids: list<string>, status_ids: list<string>, target_account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/reports")
  let body = {account_id: $account_id, status_ids: $status_ids, comment: $comment, forward: $forward, category: $category, rule_ids: $rule_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get one report with the given id.
#
# GET /api/v1/reports/{id}
# operationId: reportGet
export def "reports reportGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action_taken: bool, action_taken_at: string, action_taken_comment: string, category: string, comment: string, created_at: string, forwarded: bool, id: string, rule_ids: list<string>, status_ids: list<string>, target_account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/reports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an array of statuses scheduled by authorized user.
#
# GET /api/v1/scheduled_statuses
# operationId: getScheduledStatuses
export def "scheduled-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only statuses *OLDER* than the given max status ID. The status with the specified ID will not be included in the response.
  --since-id: string # Return only statuses *newer* than the given since status ID. The status with the specified ID will not be included in the response.
  --min-id: string # Return only statuses *immediately newer* than the given min ID. The status with the specified ID will not be included in the response.
  --limit: int # Number of scheduled statuses to return. (default: 20)
]: nothing -> table<id: string, media_attachments: list<record>, params: record<application_id: string, content_type: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_ids: list, poll: record, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/scheduled_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a scheduled status with the given id.
#
# DELETE /api/v1/scheduled_statuses/{id}
# operationId: deleteScheduledStatus
export def "scheduled-statuses delete" [
  id: string
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
  let full_url = (build-url $base $"/api/v1/scheduled_statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a scheduled status with the given id.
#
# GET /api/v1/scheduled_statuses/{id}
# operationId: getScheduledStatus
export def "scheduled-statuses get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, content_type: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_ids: list<string>, poll: record<expires_in: int, hide_totals: bool, multiple: bool, options: list>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/scheduled_statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a scheduled status's publishing date.
#
# PUT /api/v1/scheduled_statuses/{id}
# operationId: updateScheduledStatus
export def "scheduled-statuses updateScheduledStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduled-at: string # ISO 8601 Datetime at which to schedule a status.  Must be at least 5 minutes in the future.
]: any -> record<id: string, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, content_type: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_ids: list<string>, poll: record<expires_in: int, hide_totals: bool, multiple: bool, options: list>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/scheduled_statuses/($id)")
  let body = {scheduled_at: $scheduled_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View multiple statuses with the given IDs.
#
# GET /api/v1/statuses
# operationId: statusesGet
export def "statuses statusesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list # Target status IDs.
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id[]" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status using the given form field parameters.
#
# POST /api/v1/statuses
# operationId: statusCreate
export def "statuses statusCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # Text content of the status. If media_ids is provided, this becomes optional. Attaching a poll is optional while status is provided.
  --media-ids: list # Array of Attachment ids to be attached as media. If provided, status becomes optional, and poll cannot be used.  If the status is being submitted as a form, the key is 'media_ids[]', but if it's json or xml, the key is 'media_ids'.
  --polloptions: list # Array of possible poll answers. If provided, media_ids cannot be used, and poll[expires_in] must be provided.
  --pollexpires-in: int # Duration the poll should be open, in seconds. If provided, media_ids cannot be used, and poll[options] must be provided.
  --pollmultiple: oneof<nothing, bool> # Allow multiple choices on this poll.
  --pollhide-totals: oneof<nothing, bool> # Hide vote counts until the poll ends.
  --in-reply-to-id: string # ID of the status being replied to, if status is a reply.
  --sensitive: oneof<nothing, bool> # Status and attached media should be marked as sensitive.
  --spoiler-text: string # Text to be shown as a warning or subject before the actual content. Statuses are generally collapsed behind this field.
  --visibility: string@visibility-completer # Visibility of the posted status.
  --local-only: oneof<nothing, bool> # If set to true, this status will be "local only" and will NOT be federated beyond the local timeline(s). If set to false (default), this status will be federated to your followers beyond the local timeline(s).
  --federated: oneof<nothing, bool> # ***DEPRECATED***. Included for back compat only. Only used if set and local_only is not yet. If set to true, this status will be federated beyond the local timeline(s). If set to false, this status will NOT be federated beyond the local timeline(s).
  --scheduled-at: string # ISO 8601 Datetime at which to schedule a status.  Providing this parameter with a *future* time will cause ScheduledStatus to be returned instead of Status. Must be at least 5 minutes in the future.  Providing this parameter with a *past* time will cause the status to be backdated, and will not push it to the user's followers. This is intended for importing old statuses.
  --language: string # ISO 639 language code for this status.
  --content-type: string@content-type-completer # Content type to use when parsing this status.
  --interaction-policycan-favouriteautomatic-approval0: string # Nth entry for interaction_policy.can_favourite.automatic_approval.
  --interaction-policycan-favouritemanual-approval0: string # Nth entry for interaction_policy.can_favourite.manual_approval.
  --interaction-policycan-replyautomatic-approval0: string # Nth entry for interaction_policy.can_reply.automatic_approval.
  --interaction-policycan-replymanual-approval0: string # Nth entry for interaction_policy.can_reply.manual_approval.
  --interaction-policycan-reblogautomatic-approval0: string # Nth entry for interaction_policy.can_reblog.automatic_approval.
  --interaction-policycan-reblogmanual-approval0: string # Nth entry for interaction_policy.can_reblog.manual_approval.
]: any -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/statuses")
  let body = {status: $status, media_ids[]: $media_ids, poll[options][]: $polloptions, poll[expires_in]: $pollexpires_in, poll[multiple]: $pollmultiple, poll[hide_totals]: $pollhide_totals, in_reply_to_id: $in_reply_to_id, sensitive: $sensitive, spoiler_text: $spoiler_text, visibility: $visibility, local_only: $local_only, federated: $federated, scheduled_at: $scheduled_at, language: $language, content_type: $content_type, interaction_policy[can_favourite][automatic_approval][0]: $interaction_policycan_favouriteautomatic_approval0, interaction_policy[can_favourite][manual_approval][0]: $interaction_policycan_favouritemanual_approval0, interaction_policy[can_reply][automatic_approval][0]: $interaction_policycan_replyautomatic_approval0, interaction_policy[can_reply][manual_approval][0]: $interaction_policycan_replymanual_approval0, interaction_policy[can_reblog][automatic_approval][0]: $interaction_policycan_reblogautomatic_approval0, interaction_policy[can_reblog][manual_approval][0]: $interaction_policycan_reblogmanual_approval0} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete status with the given ID. The status must belong to you.
#
# DELETE /api/v1/statuses/{id}
# operationId: statusDelete
export def "statuses statusDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View status with the given ID.
#
# GET /api/v1/statuses/{id}
# operationId: statusGet
export def "statuses statusGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an existing status using the given form field parameters.
#
# PUT /api/v1/statuses/{id}
# operationId: statusEdit
export def "statuses statusEdit" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # Text content of the status. If media_ids is provided, this becomes optional. Attaching a poll is optional while status is provided.
  --media-ids: list # Array of Attachment ids to be attached as media. If provided, status becomes optional, and poll cannot be used.  If the status is being submitted as a form, the key is 'media_ids[]', but if it's json or xml, the key is 'media_ids'.
  --polloptions: list # Array of possible poll answers. If provided, media_ids cannot be used, and poll[expires_in] must be provided.
  --pollexpires-in: int # Duration the poll should be open, in seconds. If provided, media_ids cannot be used, and poll[options] must be provided.
  --pollmultiple: oneof<nothing, bool> # Allow multiple choices on this poll.
  --pollhide-totals: oneof<nothing, bool> # Hide vote counts until the poll ends.
  --sensitive: oneof<nothing, bool> # Status and attached media should be marked as sensitive.
  --spoiler-text: string # Text to be shown as a warning or subject before the actual content. Statuses are generally collapsed behind this field.
  --language: string # ISO 639 language code for this status.
  --content-type: string@content-type-completer # Content type to use when parsing this status.
]: any -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)")
  let body = {status: $status, media_ids: $media_ids, poll[options][]: $polloptions, poll[expires_in]: $pollexpires_in, poll[multiple]: $pollmultiple, poll[hide_totals]: $pollhide_totals, sensitive: $sensitive, spoiler_text: $spoiler_text, language: $language, content_type: $content_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Bookmark status with the given ID.
#
# POST /api/v1/statuses/{id}/bookmark
# operationId: statusBookmark
export def "statuses-bookmark statusBookmark" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/bookmark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return ancestors and descendants of the given status.
#
# GET /api/v1/statuses/{id}/context
# operationId: threadContext
export def "statuses-context threadContext" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ancestors: table<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, descendants: table<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: record, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/context")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Star/like/favourite the given status, if permitted.
#
# POST /api/v1/statuses/{id}/favourite
# operationId: statusFave
export def "statuses-favourite statusFave" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/favourite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View accounts that have faved/starred/liked the target status.
#
# GET /api/v1/statuses/{id}/favourited_by
# operationId: statusFavedBy
export def "statuses-favourited-by statusFavedBy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/favourited_by")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View edit history of status with the given ID.
#
# GET /api/v1/statuses/{id}/history
# operationId: statusHistoryGet
export def "statuses-history statusHistoryGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, content: string, created_at: string, emojis: list<record>, media_attachments: list<record>, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, sensitive: bool, spoiler_text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mute a status's thread. This prevents notifications from being created for future replies, likes, boosts etc in the thread of which the target status is a part.
#
# POST /api/v1/statuses/{id}/mute
# operationId: statusMute
export def "statuses-mute statusMute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/mute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pin a status to the top of your profile, and add it to your Featured ActivityPub collection.
#
# POST /api/v1/statuses/{id}/pin
# operationId: statusPin
export def "statuses-pin statusPin" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/pin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reblog/boost status with the given ID.
#
# POST /api/v1/statuses/{id}/reblog
# operationId: statusReblog
export def "statuses-reblog statusReblog" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/reblog")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View accounts that have reblogged/boosted the target status.
#
# GET /api/v1/statuses/{id}/reblogged_by
# operationId: statusBoostedBy
export def "statuses-reblogged-by statusBoostedBy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/reblogged_by")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View source text of status with the given ID. Requester must own the status.
#
# GET /api/v1/statuses/{id}/source
# operationId: statusSourceGet
export def "statuses-source statusSourceGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<content_type: string, id: string, spoiler_text: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/source")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unbookmark status with the given ID.
#
# POST /api/v1/statuses/{id}/unbookmark
# operationId: statusUnbookmark
export def "statuses-unbookmark statusUnbookmark" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/unbookmark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unstar/unlike/unfavourite the given status.
#
# POST /api/v1/statuses/{id}/unfavourite
# operationId: statusUnfave
export def "statuses-unfavourite statusUnfave" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/unfavourite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unmute a status's thread. This reenables notifications for future replies, likes, boosts etc in the thread of which the target status is a part.
#
# POST /api/v1/statuses/{id}/unmute
# operationId: statusUnmute
export def "statuses-unmute statusUnmute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/unmute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpin one of your pinned statuses.
#
# POST /api/v1/statuses/{id}/unpin
# operationId: statusUnpin
export def "statuses-unpin statusUnpin" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/unpin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unreblog/unboost status with the given ID.
#
# POST /api/v1/statuses/{id}/unreblog
# operationId: statusUnreblog
export def "statuses-unreblog statusUnreblog" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list<record>, enable_rss: bool, fields: list<record>, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, roles: list<record>, source: record<also_known_as_uris: list, fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool, status_content_type: string, web_include_boosts: bool, web_layout: string, web_visibility: string>, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, filtered: table<filter: record, keyword_matches: list, status_matches: list>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record<automatic_approval: list, manual_approval: list>, can_reblog: record<automatic_approval: list, manual_approval: list>, can_reply: record<automatic_approval: list, manual_approval: list>>, language: string, local_only: bool, media_attachments: table<blurhash: string, description: string, error: string, id: string, meta: record, preview_remote_url: string, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<record>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<following: bool, history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuses/($id)/unreblog")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate a websocket connection for live streaming of statuses and notifications.
#
# GET /api/v1/streaming
# operationId: streamGet
export def "streaming streamGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token: string # Access token for the requesting account.
  --stream: string@stream-completer # Type of stream to request.  Options are:  `user`: receive updates for the account's home timeline, and notifications for the account. `user:notification`: receive notifications for the account. `public`: receive updates for the public timeline. `public:local`: receive updates for the local timeline. `hashtag`: receive updates for a given hashtag. `hashtag:local`: receive local updates for a given hashtag. `list`: receive updates for a certain list of accounts. `direct`: receive updates for direct messages.
  --list: string # ID of the list to subscribe to. Only used if stream type is 'list'.
  --tag: string # Name of the tag to subscribe to. Only used if stream type is 'hashtag' or 'hashtag:local'.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_token" $access_token "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/streaming" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accounts that are promoted by staff, or that the user has had past positive interactions with, but is not yet following.
#
# GET /api/v1/suggestions
# operationId: getSuggestions
export def "suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/suggestions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details for a hashtag, including whether you currently follow it.
#
# GET /api/v1/tags/{tag_name}
# operationId: getTag
export def "tags get" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<following: bool, history: list<any>, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tags/($tag_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Follow a hashtag.
#
# POST /api/v1/tags/{tag_name}/follow
# operationId: followTag
export def "tags-follow followTag" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<following: bool, history: list<any>, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tags/($tag_name)/follow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unfollow a hashtag.
#
# POST /api/v1/tags/{tag_name}/unfollow
# operationId: unfollowTag
export def "tags-unfollow unfollowTag" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<following: bool, history: list<any>, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tags/($tag_name)/unfollow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See statuses/posts by accounts you follow.
#
# GET /api/v1/timelines/home
# operationId: homeTimeline
export def "timelines-home homeTimeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only statuses *OLDER* than the given max status ID. The status with the specified ID will not be included in the response.
  --since-id: string # Return only statuses *newer* than the given since status ID. The status with the specified ID will not be included in the response.
  --min-id: string # Return only statuses *immediately newer* than the given since status ID. The status with the specified ID will not be included in the response.
  --limit: int # Number of statuses to return. (default: 20)
  --local: oneof<nothing, bool> # Show only statuses posted by local accounts. (default: false)
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "local" $local "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/timelines/home" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See statuses/posts from the given list timeline.
#
# GET /api/v1/timelines/list/{id}
# operationId: listTimeline
export def "timelines-list listTimeline" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only statuses *OLDER* than the given max status ID. The status with the specified ID will not be included in the response.
  --since-id: string # Return only statuses *NEWER* than the given since status ID. The status with the specified ID will not be included in the response.
  --min-id: string # Return only statuses *NEWER* than the given since status ID. The status with the specified ID will not be included in the response.
  --limit: int # Number of statuses to return. (default: 20)
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/timelines/list/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See public statuses/posts that your instance is aware of.
#
# GET /api/v1/timelines/public
# operationId: publicTimeline
export def "timelines-public publicTimeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only statuses *OLDER* than the given max status ID. The status with the specified ID will not be included in the response.
  --since-id: string # Return only statuses *NEWER* than the given since status ID. The status with the specified ID will not be included in the response.
  --min-id: string # Return only statuses *NEWER* than the given since status ID. The status with the specified ID will not be included in the response.
  --limit: int # Number of statuses to return. (default: 20)
  --local: oneof<nothing, bool> # Show only statuses posted by local accounts. (default: false)
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "local" $local "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/timelines/public" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See public statuses that use the given hashtag (case insensitive).
#
# GET /api/v1/timelines/tag/{tag_name}
# operationId: tagTimeline
export def "timelines-tag tagTimeline" [
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-id: string # Return only statuses *OLDER* than the given max status ID. The status with the specified ID will not be included in the response.
  --since-id: string # Return only statuses *newer* than the given since status ID. The status with the specified ID will not be included in the response.
  --min-id: string # Return only statuses *immediately newer* than the given since status ID. The status with the specified ID will not be included in the response.
  --limit: int # Number of statuses to return. (default: 20)
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, embed_url: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, content_type: string, created_at: string, edited_at: string, emojis: list<record>, favourited: bool, favourites_count: int, filtered: list<record>, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record<can_favourite: record, can_reblog: record, can_reply: record>, language: string, local_only: bool, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: record<account: record, application: record, bookmarked: bool, card: record, content: string, content_type: string, created_at: string, edited_at: string, emojis: list, favourited: bool, favourites_count: int, filtered: list, id: string, in_reply_to_account_id: string, in_reply_to_id: string, interaction_policy: record, language: string, local_only: bool, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/timelines/tag/($tag_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# See info about tokens created for/by your account.
#
# GET /api/v1/tokens
# operationId: tokensInfoGet
export def "tokens tokensInfoGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order results by "last_used" (latest to oldest), or "created" (newest to oldest). (default: last_used)
  --max-id: string # Return only items after the given max item ID. The item with the specified ID will not be included in the response.
  --since-id: string # Return only items before the given item ID. The item with the specified ID will not be included in the response.
  --min-id: string # Return only items *immediately before* the given since item ID. The item with the specified ID will not be included in the response.
  --limit: int # Number of items to return. (default: 20)
]: nothing -> table<application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list, scopes: list, vapid_key: string, website: string>, created_at: string, id: string, last_used: string, name: string, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about a single token.
#
# GET /api/v1/tokens/{id}
# operationId: tokenInfoGet
export def "tokens tokenInfoGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, created_at: string, id: string, last_used: string, name: string, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the given token to set / unset the "name" property.
#
# PUT /api/v1/tokens/{id}
# operationId: tokenUpdatePut
export def "tokens tokenUpdatePut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, created_at: string, id: string, last_used: string, name: string, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invalidate the target token, removing it from the database and making it unusable.
#
# POST /api/v1/tokens/{id}/invalidate
# operationId: tokenInvalidatePost
export def "tokens-invalidate tokenInvalidatePost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application: record<client_id: string, client_secret: string, created_at: string, id: string, name: string, redirect_uri: string, redirect_uris: list<string>, scopes: list<string>, vapid_key: string, website: string>, created_at: string, id: string, last_used: string, name: string, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tokens/($id)/invalidate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Links that have been shared more than others.
#
# GET /api/v1/trends/links
# operationId: getTrendingLinks
export def "trends-links get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/trends/links")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Statuses that have been interacted with more than others.
#
# GET /api/v1/trends/statuses
# operationId: getTrendingStatuses
export def "trends-statuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/trends/statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View hashtags that are currently being used more frequently than usual.
#
# GET /api/v1/trends/tags
# operationId: getTrendingTags
export def "trends-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/trends/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get your own user model.
#
# GET /api/v1/user
# operationId: getUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<admin: bool, approved: bool, confirmation_sent_at: string, confirmed_at: string, created_at: string, disabled: bool, email: string, id: string, last_emailed_at: string, moderator: bool, reason: string, reset_password_sent_at: string, two_factor_enabled_at: string, unconfirmed_email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable 2fa for the authorized user. User's current password must be provided for verification purposes.
#
# POST /api/v1/user/2fa/disable
# operationId: TwoFactorDisablePost
export def "user-2fa-disable TwoFactorDisablePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string # User's current password, for verification.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user/2fa/disable")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enable 2fa for the authorized user, using the provided code from an authenticator app, and return an array of one-time recovery codes to allow bypassing 2fa.
#
# POST /api/v1/user/2fa/enable
# operationId: TwoFactorEnablePost
export def "user-2fa-enable TwoFactorEnablePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # 2fa code from the user's authenticator app. Sample: 123456
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user/2fa/enable")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Return a QR code png to allow the authorized user to enable 2fa for their login.
#
# GET /api/v1/user/2fa/qr.png
# operationId: TwoFactorQRCodePngGet
export def "user-2fa-qrpng TwoFactorQRCodePngGet" [
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
  let full_url = (build-url $base "/api/v1/user/2fa/qr.png")
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a QR code uri to allow the authorized user to enable 2fa for their login.
#
# GET /api/v1/user/2fa/qruri
# operationId: TwoFactorQRCodeURIGet
export def "user-2fa-qruri TwoFactorQRCodeURIGet" [
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
  let full_url = (build-url $base "/api/v1/user/2fa/qruri")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request changing the email address of authenticated user.
#
# POST /api/v1/user/email_change
# operationId: userEmailChange
export def "user-email-change userEmailChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # User's current password, for verification.
  new_email: string # Desired new email address.
]: any -> record<admin: bool, approved: bool, confirmation_sent_at: string, confirmed_at: string, created_at: string, disabled: bool, email: string, id: string, last_emailed_at: string, moderator: bool, reason: string, reset_password_sent_at: string, two_factor_enabled_at: string, unconfirmed_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user/email_change")
  let body = {password: $password, new_email: $new_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Change the password of authenticated user.
#
# POST /api/v1/user/password_change
# operationId: userPasswordChange
export def "user-password-change userPasswordChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  old_password: string # User's previous password.
  new_password: string # Desired new password. If the password does not have high enough entropy, it will be rejected. See https://github.com/wagslane/go-password-validator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user/password_change")
  let body = {old_password: $old_password, new_password: $new_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# View + page through known accounts according to given filters.
#
# GET /api/v2/admin/accounts
# operationId: adminAccountsGetV2
export def "admin-accounts adminAccountsGetV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --origin: string # Filter for `local` or `remote` accounts.
  --status: string # Filter for `active`, `pending`, `disabled`, `silenced`, or `suspended` accounts.
  --permissions: string # Filter for accounts with staff permissions (users that can manage reports).
  --role-ids: list # Filter for users with these roles.
  --invited-by: string # Lookup users invited by the account with this ID.
  --username: string # Search for the given username.
  --display-name: string # Search for the given display name.
  --by-domain: string # Filter by the given domain.
  --email: string # Lookup a user with this email.
  --ip: string # Lookup users with this IP address.
  --max-id: string # max_id in the form `[domain]/@[username]`. All results returned will be later in the alphabet than `[domain]/@[username]`. For example, if max_id = `example.org/@someone` then returned entries might contain `example.org/@someone_else`, `later.example.org/@someone`, etc. Local account IDs in this form use an empty string for the `[domain]` part, for example local account with username `someone` would be `/@someone`.
  --min-id: string # min_id in the form `[domain]/@[username]`. All results returned will be earlier in the alphabet than `[domain]/@[username]`. For example, if min_id = `example.org/@someone` then returned entries might contain `example.org/@earlier_account`, `earlier.example.org/@someone`, etc. Local account IDs in this form use an empty string for the `[domain]` part, for example local account with username `someone` would be `/@someone`.
  --limit: int # Maximum number of results to return. (default: 50)
]: nothing -> table<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, domain: string, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, ips: list<any>, locale: string, role: record<color: string, highlighted: bool, id: string, name: string, permissions: string>, silenced: bool, suspended: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin" $origin "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "permissions" $permissions "scalar") (serialize-qp "role_ids[]" $role_ids "csv") (serialize-qp "invited_by" $invited_by "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "display_name" $display_name "scalar") (serialize-qp "by_domain" $by_domain "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ip" $ip "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/admin/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all filters for the authenticated account.
#
# GET /api/v2/filters
# operationId: filtersV2Get
export def "filters filtersV2Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<context: list<string>, expires_at: string, filter_action: string, id: string, keywords: list<record>, statuses: list<record>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/filters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a single filter.
#
# POST /api/v2/filters
# operationId: filterV2Post
export def "filters filterV2Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The name of the filter.  Sample: illuminati nonsense
  context: list # The contexts in which the filter should be applied.  Sample: home, public
  --expires-in: float # Number of seconds from now that the filter should expire. If omitted, filter never expires.  Sample: 86400
  --filter-action: string@filter-action-completer # The action to be taken when a status matches this filter.  Sample: warn
  --keywords-attributeskeyword: list # Keywords to be added (if not using id param) or updated (if using id param).
  --keywords-attributeswhole-word: list # Should each keyword consider word boundaries?
  --statuses-attributesstatus-id: list # Statuses to be added to the filter.
]: any -> record<context: list<string>, expires_at: string, filter_action: string, id: string, keywords: table<id: string, keyword: string, whole_word: bool>, statuses: table<id: string, phrase: string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/filters")
  let body = {title: $title, context[]: $context, expires_in: $expires_in, filter_action: $filter_action, keywords_attributes[][keyword]: $keywords_attributeskeyword, keywords_attributes[][whole_word]: $keywords_attributeswhole_word, statuses_attributes[][status_id]: $statuses_attributesstatus_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a single filter with the given ID.
#
# DELETE /api/v2/filters/{id}
# operationId: filterV2Delete
export def "filters filterV2Delete" [
  id: string
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
  let full_url = (build-url $base $"/api/v2/filters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single filter with the given ID.
#
# GET /api/v2/filters/{id}
# operationId: filterV2Get
export def "filters filterV2Get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<context: list<string>, expires_at: string, filter_action: string, id: string, keywords: table<id: string, keyword: string, whole_word: bool>, statuses: table<id: string, phrase: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single filter with the given ID.
#
# PUT /api/v2/filters/{id}
# operationId: filterV2Put
export def "filters filterV2Put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The name of the filter.  Sample: illuminati nonsense
  --keywords-attributeskeyword: list # Keywords to be added to the created filter.
  --keywords-attributeswhole-word: list # Should each keyword consider word boundaries?
  --statuses-attributesstatus-id: list # Statuses to be added to the newly created filter.
  context: list # The contexts in which the filter should be applied.  Sample: home, public
  --expires-in: float # Number of seconds from now that the filter should expire.  Sample: 86400
  --filter-action: string@filter-action-completer # The action to be taken when a status matches this filter.  Sample: warn
]: any -> record<context: list<string>, expires_at: string, filter_action: string, id: string, keywords: table<id: string, keyword: string, whole_word: bool>, statuses: table<id: string, phrase: string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/($id)")
  let body = {title: $title, keywords_attributes[][keyword]: $keywords_attributeskeyword, keywords_attributes[][whole_word]: $keywords_attributeswhole_word, statuses_attributes[][status_id]: $statuses_attributesstatus_id, context[]: $context, expires_in: $expires_in, filter_action: $filter_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all filter keywords for a given filter.
#
# GET /api/v2/filters/{id}/keywords
# operationId: filterKeywordsGet
export def "filters-keywords filterKeywordsGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, keyword: string, whole_word: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/($id)/keywords")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a filter keyword to an existing filter.
#
# POST /api/v2/filters/{id}/keywords
# operationId: filterKeywordPost
export def "filters-keywords filterKeywordPost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyword: string # The text to be filtered  Sample: fnord
  --whole-word: oneof<nothing, bool> # Should the filter consider word boundaries?  Sample: true
]: any -> record<id: string, keyword: string, whole_word: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/($id)/keywords")
  let body = {keyword: $keyword, whole_word: $whole_word} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all filter statuses for a given filter.
#
# GET /api/v2/filters/{id}/statuses
# operationId: filterStatusesGet
export def "filters-statuses filterStatusesGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, phrase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/($id)/statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a filter status to an existing filter.
#
# POST /api/v2/filters/{id}/statuses
# operationId: filterStatusPost
export def "filters-statuses filterStatusPost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status_id: string # The ID of the status to filter.  Sample: 01HXA2NE0K8T1C70K90E74GYD0
]: any -> record<id: string, phrase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/($id)/statuses")
  let body = {status_id: $status_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a single filter keyword with the given ID.
#
# DELETE /api/v2/filters/keywords/{id}
# operationId: filterKeywordDelete
export def "filters-keywords filterKeywordDelete" [
  id: string
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
  let full_url = (build-url $base $"/api/v2/filters/keywords/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single filter keyword with the given ID.
#
# GET /api/v2/filters/keywords/{id}
# operationId: filterKeywordGet
export def "filters-keywords filterKeywordGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, keyword: string, whole_word: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/keywords/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single filter keyword with the given ID.
#
# PUT /api/v2/filters/keywords{id}
# operationId: filterKeywordPut
export def "filters-keywords-id filterKeywordPut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keyword: string # The text to be filtered  Sample: fnord
  --whole-word: oneof<nothing, bool> # Should the filter consider word boundaries?  Sample: true
]: any -> record<id: string, keyword: string, whole_word: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/keywords($id)")
  let body = {keyword: $keyword, whole_word: $whole_word} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a single filter status with the given ID.
#
# DELETE /api/v2/filters/statuses/{id}
# operationId: filterStatusDelete
export def "filters-statuses filterStatusDelete" [
  id: string
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
  let full_url = (build-url $base $"/api/v2/filters/statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single filter status with the given ID.
#
# GET /api/v2/filters/statuses/{id}
# operationId: filterStatusGet
export def "filters-statuses filterStatusGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, phrase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/filters/statuses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View instance information.
#
# GET /api/v2/instance
# operationId: instanceGetV2
export def "instance instanceGetV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_domain: string, configuration: record<accounts: record<allow_custom_css: bool, max_featured_tags: int, max_profile_fields: int>, emojis: record<emoji_size_limit: int>, media_attachments: record<description_limit: int, description_minimum: int, image_matrix_limit: int, image_size_limit: int, supported_mime_types: list, video_frame_rate_limit: int, video_matrix_limit: int, video_size_limit: int>, oidc_enabled: bool, polls: record<max_characters_per_option: int, max_expiration: int, max_options: int, min_expiration: int>, statuses: record<characters_reserved_per_url: int, max_characters: int, max_media_attachments: int, supported_mime_types: list>, translation: record<enabled: bool>, urls: record<about: string, privacy_policy: string, streaming: string, terms_of_service: string>, vapid: record<public_key: string>>, contact: record<account: record<acct: string, avatar: string, avatar_description: string, avatar_media_id: string, avatar_static: string, bot: bool, created_at: string, custom_css: string, discoverable: bool, display_name: string, emojis: list, enable_rss: bool, fields: list, followers_count: int, following_count: int, group: bool, header: string, header_description: string, header_media_id: string, header_static: string, hide_collections: bool, id: string, indexable: bool, last_status_at: string, locked: bool, moved: any, noindex: bool, note: string, role: record, roles: list, source: record, statuses_count: int, suspended: bool, theme: string, url: string, username: string>, email: string>, custom_css: string, debug: bool, description: string, description_text: string, domain: string, languages: list<string>, registrations: record<approval_required: bool, enabled: bool, message: string, min_age: int, reason_required: bool>, rules: table<id: string, text: string>, source_url: string, terms: string, terms_text: string, thumbnail: record<blurhash: string, static_url: string, thumbnail_description: string, thumbnail_static_type: string, thumbnail_type: string, url: string, versions: record<_1x: string, _2x: string>>, title: string, usage: record<users: record<active_month: int>>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/instance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns code 200 with no body if GoToSocial is "live", ie., able to respond to HTTP requests.
#
# GET /livez
# operationId: liveGet
export def "livez liveGet" [
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
  let full_url = (build-url $base "/livez")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns code 200 if GoToSocial is "live", ie., able to respond to HTTP requests.
#
# HEAD /livez
# operationId: liveHead
export def "livez liveHead" [
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
  let full_url = (build-url $base "/livez")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a compliant nodeinfo response to node info queries.
#
# GET /nodeinfo/{schema_version}
# operationId: nodeInfoGet
export def "nodeinfo nodeInfoGet" [
  schema_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<metadata: record, openRegistrations: bool, protocols: list<string>, services: record<inbound: list<string>, outbound: list<string>>, software: record<homepage: string, name: string, repository: string, version: string>, usage: record<localComments: int, localPosts: int, users: record<activeHalfYear: int, activeMonth: int, total: int>>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodeinfo/($schema_version)")
  let accept_val = ($accept | default "application/json; profile="http://nodeinfo.diaspora.software/ns/schema/2.0#"")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke an access token to make it no longer valid for use.
#
# POST /oauth/revoke
# operationId: oauthTokenRevoke
export def "oauth-revoke oauthTokenRevoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # The client ID, obtained during app registration.
  client_secret: string # The client secret, obtained during app registration.
  --body-token: string # The previously obtained token, to be invalidated.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/revoke")
  let body = {client_id: $client_id, client_secret: $client_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns code 200 with no body if GoToSocial is "ready", ie., able to connect to the database backend and do a simple SELECT.
#
# GET /readyz
# operationId: readyGet
export def "readyz readyGet" [
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
  let full_url = (build-url $base "/readyz")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns code 200 with no body if GoToSocial is "ready", ie., able to connect to the database backend and do a simple SELECT.
#
# HEAD /readyz
# operationId: readyHead
export def "readyz readyHead" [
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
  let full_url = (build-url $base "/readyz")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the featured collection (pinned posts) for a user.
#
# GET /users/{username}/collections/featured
# operationId: s2sFeaturedCollectionGet
export def "users-collections-featured s2sFeaturedCollectionGet" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_context: any, TotalItems: int, id: string, items: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/collections/featured")
  let accept_val = "application/activity+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the public outbox collection for an actor.
#
# GET /users/{username}/outbox
# operationId: s2sOutboxGet
export def "users-outbox s2sOutboxGet" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: oneof<nothing, bool> # Return response as a CollectionPage. (default: false)
  --min-id: string # Minimum ID of the next status, used for paging.
  --max-id: string # Maximum ID of the next status, used for paging.
]: nothing -> record<_context: any, first: record<id: string, items: list<string>, next: string, partOf: string, type: string>, id: string, last: record<id: string, items: list<string>, next: string, partOf: string, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "max_id" $max_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/outbox" $qp)
  let accept_val = "application/activity+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the replies collection for a status.
#
# GET /users/{username}/statuses/{status}/replies
# operationId: s2sRepliesGet
export def "users-statuses-replies s2sRepliesGet" [
  username: string
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: oneof<nothing, bool> # Return response as a CollectionPage. (default: false)
  --only-other-accounts: oneof<nothing, bool> # Return replies only from accounts other than the status owner. (default: false)
  --min-id: string # Minimum ID of the next status, used for paging.
]: nothing -> record<_context: any, first: record<id: string, items: list<string>, next: string, partOf: string, type: string>, id: string, last: record<id: string, items: list<string>, next: string, partOf: string, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "only_other_accounts" $only_other_accounts "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/statuses/($status)/replies" $qp)
  let accept_val = "application/activity+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
