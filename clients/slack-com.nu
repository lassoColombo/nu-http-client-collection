# Auto-generated client for Slack Web API v1.7.0
# Source: https://api.apis.guru/v2/specs/slack.com/1.7.0/openapi.json
# Auth: --token flag or $env.SLACK_WEB_API_TOKEN

const BASE_URL = "https://slack.com/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SLACK_WEB_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://slack.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["admin-apps-approve" "admin-apps-approved-list" "admin-apps-requests-list" "admin-apps-restrict" "admin-apps-restricted-list" "admin-conversations-archive" "admin-conversations-convert-to-private" "admin-conversations-create" "admin-conversations-delete" "admin-conversations-disconnect-shared" "admin-conversations-ekm-list-original-connected-channel-info" "admin-conversations-get-conversation-prefs" "admin-conversations-get-teams" "admin-conversations-invite" "admin-conversations-rename" "admin-conversations-restrict-access-add-group" "admin-conversations-restrict-access-list-groups" "admin-conversations-restrict-access-remove-group" "admin-conversations-search" "admin-conversations-set-conversation-prefs" "admin-conversations-set-teams" "admin-conversations-unarchive" "admin-emoji-add" "admin-emoji-add-alias" "admin-emoji-list" "admin-emoji-remove" "admin-emoji-rename" "admin-invite-requests-approve" "admin-invite-requests-approved-list" "admin-invite-requests-denied-list" "admin-invite-requests-deny" "admin-invite-requests-list" "admin-teams-admins-list" "admin-teams-create" "admin-teams-list" "admin-teams-owners-list" "admin-teams-settings-info" "admin-teams-settings-set-default-channels" "admin-teams-settings-set-description" "admin-teams-settings-set-discoverability" "admin-teams-settings-set-icon" "admin-teams-settings-set-name" "admin-usergroups-add-channels" "admin-usergroups-add-teams" "admin-usergroups-list-channels" "admin-usergroups-remove-channels" "admin-users-assign" "admin-users-invite" "admin-users-list" "admin-users-remove" "admin-users-session-invalidate" "admin-users-session-reset" "admin-users-set-admin" "admin-users-set-expiration" "admin-users-set-owner" "admin-users-set-regular" "api-test" "apps-event-authorizations-list" "apps-permissions-info" "apps-permissions-request" "apps-permissions-resources-list" "apps-permissions-scopes-list" "apps-permissions-users-list" "apps-permissions-users-request" "apps-uninstall" "auth-revoke" "auth-test" "bots-info" "calls-add" "calls-end" "calls-info" "calls-participants-add" "calls-participants-remove" "calls-update" "chat-delete" "chat-delete-scheduled-message" "chat-get-permalink" "chat-me-message" "chat-post-ephemeral" "chat-post-message" "chat-schedule-message" "chat-scheduled-messages-list" "chat-unfurl" "chat-update" "conversations-archive" "conversations-close" "conversations-create" "conversations-history" "conversations-info" "conversations-invite" "conversations-join" "conversations-kick" "conversations-leave" "conversations-list" "conversations-mark" "conversations-members" "conversations-open" "conversations-rename" "conversations-replies" "conversations-set-purpose" "conversations-set-topic" "conversations-unarchive" "dialog-open" "dnd-end-dnd" "dnd-end-snooze" "dnd-info" "dnd-set-snooze" "dnd-team-info" "emoji-list" "files-comments-delete" "files-delete" "files-info" "files-list" "files-remote-add" "files-remote-info" "files-remote-list" "files-remote-remove" "files-remote-share" "files-remote-update" "files-revoke-public-url" "files-shared-public-url" "files-upload" "migration-exchange" "oauth-access" "oauth-token" "oauth-v2-access" "pins-add" "pins-list" "pins-remove" "reactions-add" "reactions-get" "reactions-list" "reactions-remove" "reminders-add" "reminders-complete" "reminders-delete" "reminders-info" "reminders-list" "rtm-connect" "search-messages" "stars-add" "stars-list" "stars-remove" "team-access-logs" "team-billable-info" "team-info" "team-integration-logs" "team-profile-get" "usergroups-create" "usergroups-disable" "usergroups-enable" "usergroups-list" "usergroups-update" "usergroups-users-list" "usergroups-users-update" "users-conversations" "users-delete-photo" "users-get-presence" "users-identity" "users-info" "users-list" "users-lookup-by-email" "users-profile-get" "users-profile-set" "users-set-active" "users-set-photo" "users-set-presence" "views-open" "views-publish" "views-push" "views-update" "workflows-step-completed" "workflows-step-failed" "workflows-update-step" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "admin-apps-approve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.apps:write` (required) (spec name: token)
  --app-id: string # The id of the app to approve.
  --request-id: string # The id of the request to approve.
  --team-id: string
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.apps.approve" $auth.query)
  let req_body = {"app_id": $app_id, "request_id": $request_id, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List approved apps for an org or workspace.
#
# GET /admin.apps.approved.list
# Docs: https://api.slack.com/methods/admin.apps.approved.list — API method documentation
# operationId: admin_apps_approved_list
export def "admin-apps-approved-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
  --enterprise-id: string
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "enterprise_id" $enterprise_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.apps.approved.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "limit": $limit, "cursor": $cursor, "team_id": $team_id, "enterprise_id": $enterprise_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List app requests for a team/workspace.
#
# GET /admin.apps.requests.list
# Docs: https://api.slack.com/methods/admin.apps.requests.list — API method documentation
# operationId: admin_apps_requests_list
export def "admin-apps-requests-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.apps.requests.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "limit": $limit, "cursor": $cursor, "team_id": $team_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Restrict an app for installation on a workspace.
#
# POST /admin.apps.restrict
# Docs: https://api.slack.com/methods/admin.apps.restrict — API method documentation
# operationId: admin_apps_restrict
export def "admin-apps-restrict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.apps:write` (required) (spec name: token)
  --app-id: string # The id of the app to restrict.
  --request-id: string # The id of the request to restrict.
  --team-id: string
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.apps.restrict" $auth.query)
  let req_body = {"app_id": $app_id, "request_id": $request_id, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List restricted apps for an org or workspace.
#
# GET /admin.apps.restricted.list
# Docs: https://api.slack.com/methods/admin.apps.restricted.list — API method documentation
# operationId: admin_apps_restricted_list
export def "admin-apps-restricted-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.apps:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --team-id: string
  --enterprise-id: string
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "enterprise_id" $enterprise_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.apps.restricted.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "limit": $limit, "cursor": $cursor, "team_id": $team_id, "enterprise_id": $enterprise_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Archive a public or private channel.
#
# POST /admin.conversations.archive
# Docs: https://api.slack.com/methods/admin.conversations.archive — API method documentation
# operationId: admin_conversations_archive
export def "admin-conversations-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to archive.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.archive" $auth.query)
  let req_body = {"channel_id": $channel_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Convert a public channel to a private channel.
#
# POST /admin.conversations.convertToPrivate
# Docs: https://api.slack.com/methods/admin.conversations.convertToPrivate — API method documentation
# operationId: admin_conversations_convertToPrivate
export def "admin-conversations-convert-to-private" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to convert to private.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.convertToPrivate" $auth.query)
  let req_body = {"channel_id": $channel_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Create a public or private channel-based conversation.
#
# POST /admin.conversations.create
# Docs: https://api.slack.com/methods/admin.conversations.create — API method documentation
# operationId: admin_conversations_create
export def "admin-conversations-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  --description: string # Description of the public or private channel to create.
  --is-private: oneof<nothing, bool> # When `true`, creates a private channel instead of a public channel
  name: string # Name of the public or private channel to create.
  --org-wide: oneof<nothing, bool> # When `true`, the channel will be available org-wide. Note: if the channel is not `org_wide=true`, you must specify a `team_id` for this channel
  --team-id: string # The workspace to create the channel in. Note: this argument is required unless you set `org_wide=true`.
]: any -> oneof<record<channel_id: string, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.create" $auth.query)
  let req_body = {"description": $description, "is_private": $is_private, "name": $name, "org_wide": $org_wide, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "is_private") == null) { error make --unspanned { msg: "required body field 'is_private' missing: pass --is-private or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Delete a public or private channel.
#
# POST /admin.conversations.delete
# Docs: https://api.slack.com/methods/admin.conversations.delete — API method documentation
# operationId: admin_conversations_delete
export def "admin-conversations-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to delete.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.delete" $auth.query)
  let req_body = {"channel_id": $channel_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Disconnect a connected channel from one or more workspaces.
#
# POST /admin.conversations.disconnectShared
# Docs: https://api.slack.com/methods/admin.conversations.disconnectShared — API method documentation
# operationId: admin_conversations_disconnectShared
export def "admin-conversations-disconnect-shared" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to be disconnected from some workspaces.
  --leaving-team-ids: string # The team to be removed from the channel. Currently only a single team id can be specified.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.disconnectShared" $auth.query)
  let req_body = {"channel_id": $channel_id, "leaving_team_ids": $leaving_team_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all disconnected channels—i.e., channels that were once connected to other workspaces and then disconnected—and the corresponding original channel IDs for key revocation with EKM.
#
# GET /admin.conversations.ekm.listOriginalConnectedChannelInfo
# Docs: https://api.slack.com/methods/admin.conversations.ekm.listOriginalConnectedChannelInfo — API method documentation
# operationId: admin_conversations_ekm_listOriginalConnectedChannelInfo
export def "admin-conversations-ekm-list-original-connected-channel-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
  --channel-ids: string # A comma-separated list of channels to filter to.
  --team-ids: string # A comma-separated list of the workspaces to which the channels you would like returned belong.
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel_ids" $channel_ids "scalar") (serialize-qp "team_ids" $team_ids "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.ekm.listOriginalConnectedChannelInfo" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel_ids": $channel_ids, "team_ids": $team_ids, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get conversation preferences for a public or private channel.
#
# GET /admin.conversations.getConversationPrefs
# Docs: https://api.slack.com/methods/admin.conversations.getConversationPrefs — API method documentation
# operationId: admin_conversations_getConversationPrefs
export def "admin-conversations-get-conversation-prefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: string # The channel to get preferences for. (required)
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool, prefs: record<can_thread: record<type: list, user: list>, who_can_post: record<type: list, user: list>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id == null) { error make --unspanned { msg: "required query parameter 'channel_id' missing: pass --channel-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "channel_id" $channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.getConversationPrefs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"channel_id": $channel_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all the workspaces a given public or private channel is connected to within this Enterprise org.
#
# GET /admin.conversations.getTeams
# Docs: https://api.slack.com/methods/admin.conversations.getTeams — API method documentation
# operationId: admin_conversations_getTeams
export def "admin-conversations-get-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: string # The channel to determine connected workspaces within the organization for. (required)
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool, response_metadata: record<next_cursor: string>, team_ids: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id == null) { error make --unspanned { msg: "required query parameter 'channel_id' missing: pass --channel-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.getTeams" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"channel_id": $channel_id, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Invite a user to a public or private channel.
#
# POST /admin.conversations.invite
# Docs: https://api.slack.com/methods/admin.conversations.invite — API method documentation
# operationId: admin_conversations_invite
export def "admin-conversations-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel that the users will be invited to.
  user_ids: string # The users to invite.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.invite" $auth.query)
  let req_body = {"channel_id": $channel_id, "user_ids": $user_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Rename a public or private channel.
#
# POST /admin.conversations.rename
# Docs: https://api.slack.com/methods/admin.conversations.rename — API method documentation
# operationId: admin_conversations_rename
export def "admin-conversations-rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to rename.
  name: string
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.rename" $auth.query)
  let req_body = {"channel_id": $channel_id, "name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Add an allowlist of IDP groups for accessing a channel
#
# POST /admin.conversations.restrictAccess.addGroup
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.addGroup — API method documentation
# operationId: admin_conversations_restrictAccess_addGroup
export def "admin-conversations-restrict-access-add-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # The channel to link this group to.
  group_id: string # The [IDP Group](https://slack.com/help/articles/115001435788-Connect-identity-provider-groups-to-your-Enterprise-Grid-org) ID to be an allowlist for the private channel.
  --team-id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
  --body-token: string # Authentication token. Requires scope: `admin.conversations:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.restrictAccess.addGroup" $auth.query)
  let req_body = {"channel_id": $channel_id, "group_id": $group_id, "team_id": $team_id, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all IDP Groups linked to a channel
#
# GET /admin.conversations.restrictAccess.listGroups
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.listGroups — API method documentation
# operationId: admin_conversations_restrictAccess_listGroups
export def "admin-conversations-restrict-access-list-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
  --channel-id: string # required
  --team-id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($channel_id == null) { error make --unspanned { msg: "required query parameter 'channel_id' missing: pass --channel-id" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.restrictAccess.listGroups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel_id": $channel_id, "team_id": $team_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove a linked IDP group linked from a private channel
#
# POST /admin.conversations.restrictAccess.removeGroup
# Docs: https://api.slack.com/methods/admin.conversations.restrictAccess.removeGroup — API method documentation
# operationId: admin_conversations_restrictAccess_removeGroup
export def "admin-conversations-restrict-access-remove-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # The channel to remove the linked group from.
  group_id: string # The [IDP Group](https://slack.com/help/articles/115001435788-Connect-identity-provider-groups-to-your-Enterprise-Grid-org) ID to remove from the private channel.
  team_id: string # The workspace where the channel exists. This argument is required for channels only tied to one workspace, and optional for channels that are shared across an organization.
  --body-token: string # Authentication token. Requires scope: `admin.conversations:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.conversations.restrictAccess.removeGroup" $auth.query)
  let req_body = {"channel_id": $channel_id, "group_id": $group_id, "team_id": $team_id, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Search for public or private channels in an Enterprise organization.
#
# GET /admin.conversations.search
# Docs: https://api.slack.com/methods/admin.conversations.search — API method documentation
# operationId: admin_conversations_search
export def "admin-conversations-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-ids: string # Comma separated string of team IDs, signifying the workspaces to search through.
  --query: string # Name of the the channel to query by.
  --limit: int # Maximum number of items to be returned. Must be between 1 - 20 both inclusive. Default is 10.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --search-channel-types: string # The type of channel to include or exclude in the search. For example `private` will search private channels, while `private_exclude` will exclude them. For a full list of types, check the [Types section](#types).
  --sort: string # Possible values are `relevant` (search ranking based on what we think is closest), `name` (alphabetical), `member_count` (number of users in the channel), and `created` (date channel was created). You can optionally pair this with the `sort_dir` arg to change how it is sorted
  --sort-dir: string # Sort direction. Possible values are `asc` for ascending order like (1, 2, 3) or (a, b, c), and `desc` for descending order like (3, 2, 1) or (c, b, a)
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:read` (required) (spec name: token)
]: nothing -> oneof<record<channels: table<accepted_user: string, created: int, creator: string, id: string, is_archived: bool, is_channel: bool, is_frozen: bool, is_general: bool, is_member: bool, is_moved: int, is_mpim: bool, is_non_threadable: bool, is_org_shared: bool, is_pending_ext_shared: bool, is_private: bool, is_read_only: bool, is_shared: bool, is_thread_only: bool, last_read: string, latest: list, members: list, name: string, name_normalized: string, num_members: int, pending_shared: list, previous_names: list, priority: float, purpose: record, topic: record, unlinked: int, unread_count: int, unread_count_display: int>, next_cursor: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "team_ids" $team_ids "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "search_channel_types" $search_channel_types "scalar") (serialize-qp "sort" $sort "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.conversations.search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team_ids": $team_ids, "query": $query, "limit": $limit, "cursor": $cursor, "search_channel_types": $search_channel_types, "sort": $sort, "sort_dir": $sort_dir} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Set the posting permissions for a public or private channel.
#
# POST /admin.conversations.setConversationPrefs
# Docs: https://api.slack.com/methods/admin.conversations.setConversationPrefs — API method documentation
# operationId: admin_conversations_setConversationPrefs
export def "admin-conversations-set-conversation-prefs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to set the prefs for
  prefs: string # The prefs for this channel in a stringified JSON format.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.setConversationPrefs" $auth.query)
  let req_body = {"channel_id": $channel_id, "prefs": $prefs} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Set the workspaces in an Enterprise grid org that connect to a public or private channel.
#
# POST /admin.conversations.setTeams
# Docs: https://api.slack.com/methods/admin.conversations.setTeams — API method documentation
# operationId: admin_conversations_setTeams
export def "admin-conversations-set-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The encoded `channel_id` to add or remove to workspaces.
  --org-channel: oneof<nothing, bool> # True if channel has to be converted to an org channel
  --target-team-ids: string # A comma-separated list of workspaces to which the channel should be shared. Not required if the channel is being shared org-wide.
  --team-id: string # The workspace to which the channel belongs. Omit this argument if the channel is a cross-workspace shared channel.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.setTeams" $auth.query)
  let req_body = {"channel_id": $channel_id, "org_channel": $org_channel, "target_team_ids": $target_team_ids, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Unarchive a public or private channel.
#
# POST /admin.conversations.unarchive
# Docs: https://api.slack.com/methods/admin.conversations.unarchive — API method documentation
# operationId: admin_conversations_unarchive
export def "admin-conversations-unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.conversations:write` (required) (spec name: token)
  channel_id: string # The channel to unarchive.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.conversations.unarchive" $auth.query)
  let req_body = {"channel_id": $channel_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Add an emoji.
#
# POST /admin.emoji.add
# Docs: https://api.slack.com/methods/admin.emoji.add — API method documentation
# operationId: admin_emoji_add
export def "admin-emoji-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the emoji to be removed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
  url: string # The URL of a file to use as an image for the emoji. Square images under 128KB and with transparent backgrounds work best.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.add" $auth.query)
  let req_body = {"name": $name, "token": $body_token, "url": $url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Add an emoji alias.
#
# POST /admin.emoji.addAlias
# Docs: https://api.slack.com/methods/admin.emoji.addAlias — API method documentation
# operationId: admin_emoji_addAlias
export def "admin-emoji-add-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alias_for: string # The alias of the emoji.
  name: string # The name of the emoji to be aliased. Colons (`:myemoji:`) around the value are not required, although they may be included.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.addAlias" $auth.query)
  let req_body = {"alias_for": $alias_for, "name": $name, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List emoji for an Enterprise Grid organization.
#
# GET /admin.emoji.list
# Docs: https://api.slack.com/methods/admin.emoji.list — API method documentation
# operationId: admin_emoji_list
export def "admin-emoji-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.emoji.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove an emoji across an Enterprise Grid organization
#
# POST /admin.emoji.remove
# Docs: https://api.slack.com/methods/admin.emoji.remove — API method documentation
# operationId: admin_emoji_remove
export def "admin-emoji-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the emoji to be removed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.remove" $auth.query)
  let req_body = {"name": $name, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Rename an emoji.
#
# POST /admin.emoji.rename
# Docs: https://api.slack.com/methods/admin.emoji.rename — API method documentation
# operationId: admin_emoji_rename
export def "admin-emoji-rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the emoji to be renamed. Colons (`:myemoji:`) around the value are not required, although they may be included.
  new_name: string # The new name of the emoji.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.emoji.rename" $auth.query)
  let req_body = {"name": $name, "new_name": $new_name, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Approve a workspace invite request.
#
# POST /admin.inviteRequests.approve
# Docs: https://api.slack.com/methods/admin.inviteRequests.approve — API method documentation
# operationId: admin_inviteRequests_approve
export def "admin-invite-requests-approve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:write` (required) (spec name: token)
  invite_request_id: string # ID of the request to invite.
  --team-id: string # ID for the workspace where the invite request was made.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.inviteRequests.approve" $auth.query)
  let req_body = {"invite_request_id": $invite_request_id, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all approved workspace invite requests.
#
# GET /admin.inviteRequests.approved.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.approved.list — API method documentation
# operationId: admin_inviteRequests_approved_list
export def "admin-invite-requests-approved-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous API response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000, both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.inviteRequests.approved.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team_id": $team_id, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all denied workspace invite requests.
#
# GET /admin.inviteRequests.denied.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.denied.list — API method documentation
# operationId: admin_inviteRequests_denied_list
export def "admin-invite-requests-denied-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous api response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000 both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.inviteRequests.denied.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team_id": $team_id, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deny a workspace invite request.
#
# POST /admin.inviteRequests.deny
# Docs: https://api.slack.com/methods/admin.inviteRequests.deny — API method documentation
# operationId: admin_inviteRequests_deny
export def "admin-invite-requests-deny" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:write` (required) (spec name: token)
  invite_request_id: string # ID of the request to invite.
  --team-id: string # ID for the workspace where the invite request was made.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.inviteRequests.deny" $auth.query)
  let req_body = {"invite_request_id": $invite_request_id, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all pending workspace invite requests.
#
# GET /admin.inviteRequests.list
# Docs: https://api.slack.com/methods/admin.inviteRequests.list — API method documentation
# operationId: admin_inviteRequests_list
export def "admin-invite-requests-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # ID for the workspace where the invite requests were made.
  --cursor: string # Value of the `next_cursor` field sent as part of the previous API response
  --limit: int # The number of results that will be returned by the API on each invocation. Must be between 1 - 1000, both inclusive
  --hdr-token: string # Authentication token. Requires scope: `admin.invites:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.inviteRequests.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team_id": $team_id, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all of the admins on a given workspace.
#
# GET /admin.teams.admins.list
# Docs: https://api.slack.com/methods/admin.teams.admins.list — API method documentation
# operationId: admin_teams_admins_list
export def "admin-teams-admins-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
  --limit: int # The maximum number of items to return.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --team-id: string # required
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'team_id' missing: pass --team-id" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.admins.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "limit": $limit, "cursor": $cursor, "team_id": $team_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an Enterprise team.
#
# POST /admin.teams.create
# Docs: https://api.slack.com/methods/admin.teams.create — API method documentation
# operationId: admin_teams_create
export def "admin-teams-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  --team-description: string # Description for the team.
  --team-discoverability: string # Who can join the team. A team's discoverability can be `open`, `closed`, `invite_only`, or `unlisted`.
  team_domain: string # Team domain (for example, slacksoftballteam).
  team_name: string # Team name (for example, Slack Softball Team).
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.teams.create" $auth.query)
  let req_body = {"team_description": $team_description, "team_discoverability": $team_discoverability, "team_domain": $team_domain, "team_name": $team_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all teams on an Enterprise organization
#
# GET /admin.teams.list
# Docs: https://api.slack.com/methods/admin.teams.list — API method documentation
# operationId: admin_teams_list
export def "admin-teams-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return. Must be between 1 - 100 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all of the owners on a given workspace.
#
# GET /admin.teams.owners.list
# Docs: https://api.slack.com/methods/admin.teams.owners.list — API method documentation
# operationId: admin_teams_owners_list
export def "admin-teams-owners-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
  --team-id: string # required
  --limit: int # The maximum number of items to return. Must be between 1 - 1000 both inclusive.
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'team_id' missing: pass --team-id" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.owners.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "team_id": $team_id, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetch information about settings in a workspace
#
# GET /admin.teams.settings.info
# Docs: https://api.slack.com/methods/admin.teams.settings.info — API method documentation
# operationId: admin_teams_settings_info
export def "admin-teams-settings-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # required
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'team_id' missing: pass --team-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.teams.settings.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team_id": $team_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Set the default channels of a workspace.
#
# POST /admin.teams.settings.setDefaultChannels
# Docs: https://api.slack.com/methods/admin.teams.settings.setDefaultChannels — API method documentation
# operationId: admin_teams_settings_setDefaultChannels
export def "admin-teams-settings-set-default-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_ids: string # An array of channel IDs.
  team_id: string # ID for the workspace to set the default channel for.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.settings.setDefaultChannels" $auth.query)
  let req_body = {"channel_ids": $channel_ids, "team_id": $team_id, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Set the description of a given workspace.
#
# POST /admin.teams.settings.setDescription
# Docs: https://api.slack.com/methods/admin.teams.settings.setDescription — API method documentation
# operationId: admin_teams_settings_setDescription
export def "admin-teams-settings-set-description" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  description: string # The new description for the workspace.
  team_id: string # ID for the workspace to set the description for.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.teams.settings.setDescription" $auth.query)
  let req_body = {"description": $description, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# An API method that allows admins to set the discoverability of a given workspace
#
# POST /admin.teams.settings.setDiscoverability
# Docs: https://api.slack.com/methods/admin.teams.settings.setDiscoverability — API method documentation
# operationId: admin_teams_settings_setDiscoverability
export def "admin-teams-settings-set-discoverability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  discoverability: string # This workspace's discovery setting. It must be set to one of `open`, `invite_only`, `closed`, or `unlisted`.
  team_id: string # The ID of the workspace to set discoverability on.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.teams.settings.setDiscoverability" $auth.query)
  let req_body = {"discoverability": $discoverability, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Sets the icon of a workspace.
#
# POST /admin.teams.settings.setIcon
# Docs: https://api.slack.com/methods/admin.teams.settings.setIcon — API method documentation
# operationId: admin_teams_settings_setIcon
export def "admin-teams-settings-set-icon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image_url: string # Image URL for the icon
  team_id: string # ID for the workspace to set the icon for.
  --body-token: string # Authentication token. Requires scope: `admin.teams:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin.teams.settings.setIcon" $auth.query)
  let req_body = {"image_url": $image_url, "team_id": $team_id, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Set the name of a given workspace.
#
# POST /admin.teams.settings.setName
# Docs: https://api.slack.com/methods/admin.teams.settings.setName — API method documentation
# operationId: admin_teams_settings_setName
export def "admin-teams-settings-set-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  name: string # The new name of the workspace.
  team_id: string # ID for the workspace to set the name for.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.teams.settings.setName" $auth.query)
  let req_body = {"name": $name, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Add one or more default channels to an IDP group.
#
# POST /admin.usergroups.addChannels
# Docs: https://api.slack.com/methods/admin.usergroups.addChannels — API method documentation
# operationId: admin_usergroups_addChannels
export def "admin-usergroups-add-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:write` (required) (spec name: token)
  channel_ids: string # Comma separated string of channel IDs.
  --team-id: string # The workspace to add default channels in.
  usergroup_id: string # ID of the IDP group to add default channels for.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.usergroups.addChannels" $auth.query)
  let req_body = {"channel_ids": $channel_ids, "team_id": $team_id, "usergroup_id": $usergroup_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Associate one or more default workspaces with an organization-wide IDP group.
#
# POST /admin.usergroups.addTeams
# Docs: https://api.slack.com/methods/admin.usergroups.addTeams — API method documentation
# operationId: admin_usergroups_addTeams
export def "admin-usergroups-add-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.teams:write` (required) (spec name: token)
  --auto-provision: oneof<nothing, bool> # When `true`, this method automatically creates new workspace accounts for the IDP group members.
  team_ids: string # A comma separated list of encoded team (workspace) IDs. Each workspace *MUST* belong to the organization associated with the token.
  usergroup_id: string # An encoded usergroup (IDP Group) ID.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.usergroups.addTeams" $auth.query)
  let req_body = {"auto_provision": $auto_provision, "team_ids": $team_ids, "usergroup_id": $usergroup_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List the channels linked to an org-level IDP group (user group).
#
# GET /admin.usergroups.listChannels
# Docs: https://api.slack.com/methods/admin.usergroups.listChannels — API method documentation
# operationId: admin_usergroups_listChannels
export def "admin-usergroups-list-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usergroup-id: string # ID of the IDP group to list default channels for. (required)
  --team-id: string # ID of the the workspace.
  --include-num-members: oneof<nothing, bool> # Flag to include or exclude the count of members per channel.
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($usergroup_id == null) { error make --unspanned { msg: "required query parameter 'usergroup_id' missing: pass --usergroup-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "usergroup_id" $usergroup_id "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "include_num_members" $include_num_members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.usergroups.listChannels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"usergroup_id": $usergroup_id, "team_id": $team_id, "include_num_members": $include_num_members} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove one or more default channels from an org-level IDP group (user group).
#
# POST /admin.usergroups.removeChannels
# Docs: https://api.slack.com/methods/admin.usergroups.removeChannels — API method documentation
# operationId: admin_usergroups_removeChannels
export def "admin-usergroups-remove-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.usergroups:write` (required) (spec name: token)
  channel_ids: string # Comma-separated string of channel IDs
  usergroup_id: string # ID of the IDP Group
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.usergroups.removeChannels" $auth.query)
  let req_body = {"channel_ids": $channel_ids, "usergroup_id": $usergroup_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Add an Enterprise user to a workspace.
#
# POST /admin.users.assign
# Docs: https://api.slack.com/methods/admin.users.assign — API method documentation
# operationId: admin_users_assign
export def "admin-users-assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  --channel-ids: string # Comma separated values of channel IDs to add user in the new workspace.
  --is-restricted: oneof<nothing, bool> # True if user should be added to the workspace as a guest.
  --is-ultra-restricted: oneof<nothing, bool> # True if user should be added to the workspace as a single-channel guest.
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to add to the workspace.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.assign" $auth.query)
  let req_body = {"channel_ids": $channel_ids, "is_restricted": $is_restricted, "is_ultra_restricted": $is_ultra_restricted, "team_id": $team_id, "user_id": $user_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Invite a user to a workspace.
#
# POST /admin.users.invite
# Docs: https://api.slack.com/methods/admin.users.invite — API method documentation
# operationId: admin_users_invite
export def "admin-users-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  channel_ids: string # A comma-separated list of `channel_id`s for this user to join. At least one channel is required.
  --custom-message: string # An optional message to send to the user in the invite email.
  email: string # The email address of the person to invite.
  --guest-expiration-ts: string # Timestamp when guest account should be disabled. Only include this timestamp if you are inviting a guest user and you want their account to expire on a certain date.
  --is-restricted: oneof<nothing, bool> # Is this user a multi-channel guest user? (default: false)
  --is-ultra-restricted: oneof<nothing, bool> # Is this user a single channel guest user? (default: false)
  --real-name: string # Full name of the user.
  --resend: oneof<nothing, bool> # Allow this invite to be resent in the future if a user has not signed up yet. (default: false)
  team_id: string # The ID (`T1234`) of the workspace.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.invite" $auth.query)
  let req_body = {"channel_ids": $channel_ids, "custom_message": $custom_message, "email": $email, "guest_expiration_ts": $guest_expiration_ts, "is_restricted": $is_restricted, "is_ultra_restricted": $is_ultra_restricted, "real_name": $real_name, "resend": $resend, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List users on a workspace
#
# GET /admin.users.list
# Docs: https://api.slack.com/methods/admin.users.list — API method documentation
# operationId: admin_users_list
export def "admin-users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The ID (`T1234`) of the workspace. (required)
  --cursor: string # Set `cursor` to `next_cursor` returned by the previous call to list items in the next page.
  --limit: int # Limit for how many users to be retrieved per page
  --hdr-token: string # Authentication token. Requires scope: `admin.users:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'team_id' missing: pass --team-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin.users.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team_id": $team_id, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove a user from a workspace.
#
# POST /admin.users.remove
# Docs: https://api.slack.com/methods/admin.users.remove — API method documentation
# operationId: admin_users_remove
export def "admin-users-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to remove.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.remove" $auth.query)
  let req_body = {"team_id": $team_id, "user_id": $user_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Invalidate a single session for a user by session_id
#
# POST /admin.users.session.invalidate
# Docs: https://api.slack.com/methods/admin.users.session.invalidate — API method documentation
# operationId: admin_users_session_invalidate
export def "admin-users-session-invalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  session_id: int
  team_id: string # ID of the team that the session belongs to
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.session.invalidate" $auth.query)
  let req_body = {"session_id": $session_id, "team_id": $team_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Wipes all valid sessions on all devices for a given user
#
# POST /admin.users.session.reset
# Docs: https://api.slack.com/methods/admin.users.session.reset — API method documentation
# operationId: admin_users_session_reset
export def "admin-users-session-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  --mobile-only: oneof<nothing, bool> # Only expire mobile sessions (default: false)
  user_id: string # The ID of the user to wipe sessions for
  --web-only: oneof<nothing, bool> # Only expire web sessions (default: false)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.session.reset" $auth.query)
  let req_body = {"mobile_only": $mobile_only, "user_id": $user_id, "web_only": $web_only} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Set an existing guest, regular user, or owner to be an admin user.
#
# POST /admin.users.setAdmin
# Docs: https://api.slack.com/methods/admin.users.setAdmin — API method documentation
# operationId: admin_users_setAdmin
export def "admin-users-set-admin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to designate as an admin.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.setAdmin" $auth.query)
  let req_body = {"team_id": $team_id, "user_id": $user_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Set an expiration for a guest user
#
# POST /admin.users.setExpiration
# Docs: https://api.slack.com/methods/admin.users.setExpiration — API method documentation
# operationId: admin_users_setExpiration
export def "admin-users-set-expiration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  expiration_ts: int # Timestamp when guest account should be disabled.
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to set an expiration for.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.setExpiration" $auth.query)
  let req_body = {"expiration_ts": $expiration_ts, "team_id": $team_id, "user_id": $user_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Set an existing guest, regular user, or admin user to be a workspace owner.
#
# POST /admin.users.setOwner
# Docs: https://api.slack.com/methods/admin.users.setOwner — API method documentation
# operationId: admin_users_setOwner
export def "admin-users-set-owner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # Id of the user to promote to owner.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.setOwner" $auth.query)
  let req_body = {"team_id": $team_id, "user_id": $user_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Set an existing guest user, admin user, or owner to be a regular user.
#
# POST /admin.users.setRegular
# Docs: https://api.slack.com/methods/admin.users.setRegular — API method documentation
# operationId: admin_users_setRegular
export def "admin-users-set-regular" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `admin.users:write` (required) (spec name: token)
  team_id: string # The ID (`T1234`) of the workspace.
  user_id: string # The ID of the user to designate as a regular user.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/admin.users.setRegular" $auth.query)
  let req_body = {"team_id": $team_id, "user_id": $user_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Checks API calling code.
#
# GET /api.test
# Docs: https://api.slack.com/methods/api.test — API method documentation
# operationId: api_test
export def "api-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --error: string # Error response to return
  --foo: string # example property to return
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "error" $error "scalar") (serialize-qp "foo" $foo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api.test" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"error": $error, "foo": $foo} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of authorizations for the given event context. Each authorization represents an app installation that the event is visible to.
#
# GET /apps.event.authorizations.list
# Docs: https://api.slack.com/methods/apps.event.authorizations.list — API method documentation
# operationId: apps_event_authorizations_list
export def "apps-event-authorizations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-context: string # required
  --cursor: string
  --limit: int
  --hdr-token: string # Authentication token. Requires scope: `authorizations:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_context == null) { error make --unspanned { msg: "required query parameter 'event_context' missing: pass --event-context" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "event_context" $event_context "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.event.authorizations.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"event_context": $event_context, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of permissions this app has on a team.
#
# GET /apps.permissions.info
# Docs: https://api.slack.com/methods/apps.permissions.info — API method documentation
# operationId: apps_permissions_info
export def "apps-permissions-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (spec name: token)
]: nothing -> oneof<record<info: record<app_home: record<resources: record, scopes: list>, channel: record<resources: record, scopes: list>, group: record<resources: record, scopes: list>, im: record<resources: record, scopes: list>, mpim: record<resources: record, scopes: list>, team: record<resources: record, scopes: list>>, ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows an app to request additional scopes
#
# GET /apps.permissions.request
# Docs: https://api.slack.com/methods/apps.permissions.request — API method documentation
# operationId: apps_permissions_request
export def "apps-permissions-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --scopes: string # A comma separated list of scopes to request for (required)
  --trigger-id: string # Token used to trigger the permissions API (required)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($scopes == null) { error make --unspanned { msg: "required query parameter 'scopes' missing: pass --scopes" } }
  if ($trigger_id == null) { error make --unspanned { msg: "required query parameter 'trigger_id' missing: pass --trigger-id" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "scopes" $scopes "scalar") (serialize-qp "trigger_id" $trigger_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.request" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "scopes": $scopes, "trigger_id": $trigger_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of resource grants this app has on a team.
#
# GET /apps.permissions.resources.list
# Docs: https://api.slack.com/methods/apps.permissions.resources.list — API method documentation
# operationId: apps_permissions_resources_list
export def "apps-permissions-resources-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --limit: int # The maximum number of items to return.
]: nothing -> oneof<record<ok: bool, resources: table<id: string, type: string>, response_metadata: record<next_cursor: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.resources.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of scopes this app has on a team.
#
# GET /apps.permissions.scopes.list
# Docs: https://api.slack.com/methods/apps.permissions.scopes.list — API method documentation
# operationId: apps_permissions_scopes_list
export def "apps-permissions-scopes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool, scopes: record<app_home: list<string>, channel: list<string>, group: list<string>, im: list<string>, mpim: list<string>, team: list<string>, user: list<string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.scopes.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns list of user grants and corresponding scopes this app has on a team.
#
# GET /apps.permissions.users.list
# Docs: https://api.slack.com/methods/apps.permissions.users.list — API method documentation
# operationId: apps_permissions_users_list
export def "apps-permissions-users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --limit: int # The maximum number of items to return.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.users.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Enables an app to trigger a permissions modal to grant an app access to a user access scope.
#
# GET /apps.permissions.users.request
# Docs: https://api.slack.com/methods/apps.permissions.users.request — API method documentation
# operationId: apps_permissions_users_request
export def "apps-permissions-users-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --scopes: string # A comma separated list of user scopes to request for (required)
  --trigger-id: string # Token used to trigger the request (required)
  --user: string # The user this scope is being requested for (required)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($scopes == null) { error make --unspanned { msg: "required query parameter 'scopes' missing: pass --scopes" } }
  if ($trigger_id == null) { error make --unspanned { msg: "required query parameter 'trigger_id' missing: pass --trigger-id" } }
  if ($user == null) { error make --unspanned { msg: "required query parameter 'user' missing: pass --user" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "scopes" $scopes "scalar") (serialize-qp "trigger_id" $trigger_id "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.permissions.users.request" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "scopes": $scopes, "trigger_id": $trigger_id, "user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Uninstalls your app from a workspace.
#
# GET /apps.uninstall
# Docs: https://api.slack.com/methods/apps.uninstall — API method documentation
# operationId: apps_uninstall
export def "apps-uninstall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (spec name: token)
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps.uninstall" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "client_id": $client_id, "client_secret": $client_secret} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Revokes a token.
#
# GET /auth.revoke
# Docs: https://api.slack.com/methods/auth.revoke — API method documentation
# operationId: auth_revoke
export def "auth-revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --test: oneof<nothing, bool> # Setting this parameter to `1` triggers a _testing mode_ where the specified token will not actually be revoked.
]: nothing -> oneof<record<ok: bool, revoked: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "test" $test "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auth.revoke" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "test": $test} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Checks authentication & identity.
#
# GET /auth.test
# Docs: https://api.slack.com/methods/auth.test — API method documentation
# operationId: auth_test
export def "auth-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record<bot_id: string, is_enterprise_install: bool, ok: bool, team: string, team_id: string, url: string, user: string, user_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/auth.test" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets information about a bot user.
#
# GET /bots.info
# Docs: https://api.slack.com/methods/bots.info — API method documentation
# operationId: bots_info
export def "bots-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (required) (spec name: token)
  --bot: string # Bot user to get info on
]: nothing -> oneof<record<bot: record<app_id: string, deleted: bool, icons: record<image_36: string, image_48: string, image_72: string>, id: string, name: string, updated: int, user_id: string>, ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "bot" $bot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bots.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "bot": $bot} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Registers a new Call.
#
# POST /calls.add
# Docs: https://api.slack.com/methods/calls.add — API method documentation
# operationId: calls_add
export def "calls-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  --created-by: string # The valid Slack user ID of the user who created this Call. When this method is called with a user token, the `created_by` field is optional and defaults to the authed user of the token. Otherwise, the field is required.
  --date-start: int # Call start time in UTC UNIX timestamp format
  --desktop-app-join-url: string # When supplied, available Slack clients will attempt to directly launch the 3rd-party Call with this URL.
  --external-display-id: string # An optional, human-readable ID supplied by the 3rd-party Call provider. If supplied, this ID will be displayed in the Call object.
  external_unique_id: string # An ID supplied by the 3rd-party Call provider. It must be unique across all Calls from that service.
  join_url: string # The URL required for a client to join the Call.
  --title: string # The name of the Call.
  --users: string # The list of users to register as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/calls.add" $auth.query)
  let req_body = {"created_by": $created_by, "date_start": $date_start, "desktop_app_join_url": $desktop_app_join_url, "external_display_id": $external_display_id, "external_unique_id": $external_unique_id, "join_url": $join_url, "title": $title, "users": $users} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Ends a Call.
#
# POST /calls.end
# Docs: https://api.slack.com/methods/calls.end — API method documentation
# operationId: calls_end
export def "calls-end" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  --duration: int # Call duration in seconds
  id: string # `id` returned when registering the call using the [`calls.add`](/methods/calls.add) method.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/calls.end" $auth.query)
  let req_body = {"duration": $duration, "id": $id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Returns information about a Call.
#
# GET /calls.info
# Docs: https://api.slack.com/methods/calls.info — API method documentation
# operationId: calls_info
export def "calls-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # `id` of the Call returned by the [`calls.add`](/methods/calls.add) method. (required)
  --hdr-token: string # Authentication token. Requires scope: `calls:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id == null) { error make --unspanned { msg: "required query parameter 'id' missing: pass --id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calls.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Registers new participants added to a Call.
#
# POST /calls.participants.add
# Docs: https://api.slack.com/methods/calls.participants.add — API method documentation
# operationId: calls_participants_add
export def "calls-participants-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  users: string # The list of users to add as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/calls.participants.add" $auth.query)
  let req_body = {"id": $id, "users": $users} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Registers participants removed from a Call.
#
# POST /calls.participants.remove
# Docs: https://api.slack.com/methods/calls.participants.remove — API method documentation
# operationId: calls_participants_remove
export def "calls-participants-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  users: string # The list of users to remove as participants in the Call. [Read more on how to specify users here](/apis/calls#users).
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/calls.participants.remove" $auth.query)
  let req_body = {"id": $id, "users": $users} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Updates information about a Call.
#
# POST /calls.update
# Docs: https://api.slack.com/methods/calls.update — API method documentation
# operationId: calls_update
export def "calls-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `calls:write` (required) (spec name: token)
  --desktop-app-join-url: string # When supplied, available Slack clients will attempt to directly launch the 3rd-party Call with this URL.
  id: string # `id` returned by the [`calls.add`](/methods/calls.add) method.
  --join-url: string # The URL required for a client to join the Call.
  --title: string # The name of the Call.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/calls.update" $auth.query)
  let req_body = {"desktop_app_join_url": $desktop_app_join_url, "id": $id, "join_url": $join_url, "title": $title} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Deletes a message.
#
# POST /chat.delete
# Docs: https://api.slack.com/methods/chat.delete — API method documentation
# operationId: chat_delete
export def "chat-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (spec name: token)
  --as-user: oneof<nothing, bool> # Pass true to delete the message as the authed user with `chat:write:user` scope. [Bot users](/bot-users) in this context are considered authed users. If unused or false, the message will be deleted with `chat:write:bot` scope.
  --channel: string # Channel containing the message to be deleted.
  --ts: float # Timestamp of the message to be deleted.
]: any -> oneof<record<channel: string, ok: bool, ts: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.delete" $auth.query)
  let req_body = {"as_user": $as_user, "channel": $channel, "ts": $ts} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Deletes a pending scheduled message from the queue.
#
# POST /chat.deleteScheduledMessage
# Docs: https://api.slack.com/methods/chat.deleteScheduledMessage — API method documentation
# operationId: chat_deleteScheduledMessage
export def "chat-delete-scheduled-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
  --as-user: oneof<nothing, bool> # Pass true to delete the message as the authed user with `chat:write:user` scope. [Bot users](/bot-users) in this context are considered authed users. If unused or false, the message will be deleted with `chat:write:bot` scope.
  channel: string # The channel the scheduled_message is posting to
  scheduled_message_id: string # `scheduled_message_id` returned from call to chat.scheduleMessage
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/chat.deleteScheduledMessage" $auth.query)
  let req_body = {"as_user": $as_user, "channel": $channel, "scheduled_message_id": $scheduled_message_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve a permalink URL for a specific extant message
#
# GET /chat.getPermalink
# Docs: https://api.slack.com/methods/chat.getPermalink — API method documentation
# operationId: chat_getPermalink
export def "chat-get-permalink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
  --channel: string # The ID of the conversation or channel containing the message (required)
  --message-ts: string # A message's `ts` value, uniquely identifying it within a channel (required)
]: nothing -> oneof<record<channel: string, ok: bool, permalink: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($channel == null) { error make --unspanned { msg: "required query parameter 'channel' missing: pass --channel" } }
  if ($message_ts == null) { error make --unspanned { msg: "required query parameter 'message_ts' missing: pass --message-ts" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "message_ts" $message_ts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat.getPermalink" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel, "message_ts": $message_ts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Share a me message into a channel.
#
# POST /chat.meMessage
# Docs: https://api.slack.com/methods/chat.meMessage — API method documentation
# operationId: chat_meMessage
export def "chat-me-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (spec name: token)
  --channel: string # Channel to send message to. Can be a public channel, private group or IM channel. Can be an encoded ID, or a name.
  --text: string # Text of the message to send.
]: any -> oneof<record<channel: string, ok: bool, ts: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.meMessage" $auth.query)
  let req_body = {"channel": $channel, "text": $text} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Sends an ephemeral message to a user in a channel.
#
# POST /chat.postEphemeral
# Docs: https://api.slack.com/methods/chat.postEphemeral — API method documentation
# operationId: chat_postEphemeral
export def "chat-post-ephemeral" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
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
]: any -> oneof<record<message_ts: string, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/chat.postEphemeral" $auth.query)
  let req_body = {"as_user": $as_user, "attachments": $attachments, "blocks": $blocks, "channel": $channel, "icon_emoji": $icon_emoji, "icon_url": $icon_url, "link_names": $link_names, "parse": $parse, "text": $text, "thread_ts": $thread_ts, "user": $user, "username": $username} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Sends a message to a channel.
#
# POST /chat.postMessage
# Docs: https://api.slack.com/methods/chat.postMessage — API method documentation
# operationId: chat_postMessage
export def "chat-post-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
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
]: any -> oneof<record<channel: string, message: record<attachments: list<record>, blocks: list<record>, bot_id: list<any>, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, client_msg_id: string, comment: record<comment: string, created: int, id: string, is_intro: bool, is_starred: bool, num_stars: int, pinned_info: record, pinned_to: list, reactions: list, timestamp: int, user: string>, display_as_bot: bool, file: record<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, files: list<record>, icons: record<emoji: string, image_64: string>, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list<string>, purpose: string, reactions: list<record>, reply_count: int, reply_users: list<string>, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record<avatar_hash: string, display_name: string, display_name_normalized: string, first_name: string, image_72: string, is_restricted: bool, is_ultra_restricted: bool, name: string, real_name: string, real_name_normalized: string, team: string>, user_team: string, username: string>, ok: bool, ts: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/chat.postMessage" $auth.query)
  let req_body = {"as_user": $as_user, "attachments": $attachments, "blocks": $blocks, "channel": $channel, "icon_emoji": $icon_emoji, "icon_url": $icon_url, "link_names": $link_names, "mrkdwn": $mrkdwn, "parse": $parse, "reply_broadcast": $reply_broadcast, "text": $text, "thread_ts": $thread_ts, "unfurl_links": $unfurl_links, "unfurl_media": $unfurl_media, "username": $username} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Schedules a message to be sent to a channel.
#
# POST /chat.scheduleMessage
# Docs: https://api.slack.com/methods/chat.scheduleMessage — API method documentation
# operationId: chat_scheduleMessage
export def "chat-schedule-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (spec name: token)
  --as-user: oneof<nothing, bool> # Pass true to post the message as the authed user, instead of as a bot. Defaults to false. See [chat.postMessage](chat.postMessage#authorship).
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string.
  --blocks: string # A JSON-based array of structured blocks, presented as a URL-encoded string.
  --channel: string # Channel, private group, or DM channel to send message to. Can be an encoded ID, or a name. See [below](#channels) for more details.
  --link-names: oneof<nothing, bool> # Find and link channel names and usernames.
  --parse: string # Change how messages are treated. Defaults to `none`. See [chat.postMessage](chat.postMessage#formatting).
  --post-at: string # Unix EPOCH timestamp of time in future to send the message.
  --reply-broadcast: oneof<nothing, bool> # Used in conjunction with `thread_ts` and indicates whether reply should be made visible to everyone in the channel or conversation. Defaults to `false`.
  --text: string # How this field works and whether it is required depends on other fields you use in your API call. [See below](#text_usage) for more detail.
  --thread-ts: float # Provide another message's `ts` value to make this message a reply. Avoid using a reply's `ts` value; use its parent instead.
  --unfurl-links: oneof<nothing, bool> # Pass true to enable unfurling of primarily text-based content.
  --unfurl-media: oneof<nothing, bool> # Pass false to disable unfurling of media content.
]: any -> oneof<record<channel: string, message: record<bot_id: string, bot_profile: record<app_id: string, deleted: bool, icons: record, id: string, name: string, team_id: string, updated: int>, team: string, text: string, type: string, user: string, username: string>, ok: bool, post_at: int, scheduled_message_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat.scheduleMessage" $auth.query)
  let req_body = {"as_user": $as_user, "attachments": $attachments, "blocks": $blocks, "channel": $channel, "link_names": $link_names, "parse": $parse, "post_at": $post_at, "reply_broadcast": $reply_broadcast, "text": $text, "thread_ts": $thread_ts, "unfurl_links": $unfurl_links, "unfurl_media": $unfurl_media} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Returns a list of scheduled messages.
#
# GET /chat.scheduledMessages.list
# Docs: https://api.slack.com/methods/chat.scheduledMessages.list — API method documentation
# operationId: chat_scheduledMessages_list
export def "chat-scheduled-messages-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel: string # The channel of the scheduled messages
  --latest: float # A UNIX timestamp of the latest value in the time range
  --oldest: float # A UNIX timestamp of the oldest value in the time range
  --limit: int # Maximum number of original entries to return.
  --cursor: string # For pagination purposes, this is the `cursor` value returned from a previous call to `chat.scheduledmessages.list` indicating where you want to start this call from.
  --hdr-token: string # Authentication token. Requires scope: `none` (spec name: token)
]: nothing -> oneof<record<ok: bool, response_metadata: record<next_cursor: string>, scheduled_messages: table<channel_id: string, date_created: int, id: string, post_at: int, text: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channel" $channel "scalar") (serialize-qp "latest" $latest "scalar") (serialize-qp "oldest" $oldest "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat.scheduledMessages.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"channel": $channel, "latest": $latest, "oldest": $oldest, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provide custom unfurl behavior for user-posted URLs
#
# POST /chat.unfurl
# Docs: https://api.slack.com/methods/chat.unfurl — API method documentation
# operationId: chat_unfurl
export def "chat-unfurl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `links:write` (required) (spec name: token)
  channel: string # Channel ID of the message
  ts: string # Timestamp of the message to add unfurl behavior to.
  --unfurls: string # URL-encoded JSON map with keys set to URLs featured in the the message, pointing to their unfurl blocks or message attachments.
  --user-auth-message: string # Provide a simply-formatted string to send as an ephemeral message to the user as invitation to authenticate further and enable full unfurling behavior
  --user-auth-required: oneof<nothing, bool> # Set to `true` or `1` to indicate the user must install your Slack app to trigger unfurls for this domain
  --user-auth-url: string # Send users to this custom URL where they will complete authentication in your app to fully trigger unfurling. Value should be properly URL-encoded.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/chat.unfurl" $auth.query)
  let req_body = {"channel": $channel, "ts": $ts, "unfurls": $unfurls, "user_auth_message": $user_auth_message, "user_auth_required": $user_auth_required, "user_auth_url": $user_auth_url} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Updates a message.
#
# POST /chat.update
# Docs: https://api.slack.com/methods/chat.update — API method documentation
# operationId: chat_update
export def "chat-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `chat:write` (required) (spec name: token)
  --as-user: string # Pass true to update the message as the authed user. [Bot users](/bot-users) in this context are considered authed users.
  --attachments: string # A JSON-based array of structured attachments, presented as a URL-encoded string. This field is required when not presenting `text`. If you don't include this field, the message's previous `attachments` will be retained. To remove previous `attachments`, include an empty array for this field.
  --blocks: string # A JSON-based array of [structured blocks](/block-kit/building), presented as a URL-encoded string. If you don't include this field, the message's previous `blocks` will be retained. To remove previous `blocks`, include an empty array for this field.
  channel: string # Channel containing the message to be updated.
  --link-names: string # Find and link channel names and usernames. Defaults to `none`. If you do not specify a value for this field, the original value set for the message will be overwritten with the default, `none`.
  --parse: string # Change how messages are treated. Defaults to `client`, unlike `chat.postMessage`. Accepts either `none` or `full`. If you do not specify a value for this field, the original value set for the message will be overwritten with the default, `client`.
  --text: string # New text for the message, using the [default formatting rules](/reference/surfaces/formatting). It's not required when presenting `blocks` or `attachments`.
  ts: string # Timestamp of the message to be updated.
]: any -> oneof<record<channel: string, message: record<attachments: list<record>, blocks: record, text: string>, ok: bool, text: string, ts: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/chat.update" $auth.query)
  let req_body = {"as_user": $as_user, "attachments": $attachments, "blocks": $blocks, "channel": $channel, "link_names": $link_names, "parse": $parse, "text": $text, "ts": $ts} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Archives a conversation.
#
# POST /conversations.archive
# Docs: https://api.slack.com/methods/conversations.archive — API method documentation
# operationId: conversations_archive
export def "conversations-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to archive
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.archive" $auth.query)
  let req_body = {"channel": $channel} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Closes a direct message or multi-person direct message.
#
# POST /conversations.close
# Docs: https://api.slack.com/methods/conversations.close — API method documentation
# operationId: conversations_close
export def "conversations-close" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to close.
]: any -> oneof<record<already_closed: bool, no_op: bool, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.close" $auth.query)
  let req_body = {"channel": $channel} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Initiates a public or private channel-based conversation
#
# POST /conversations.create
# Docs: https://api.slack.com/methods/conversations.create — API method documentation
# operationId: conversations_create
export def "conversations-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --is-private: oneof<nothing, bool> # Create a private channel instead of a public one
  --name: string # Name of the public or private channel to create
]: any -> oneof<record<channel: list<any>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.create" $auth.query)
  let req_body = {"is_private": $is_private, "name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Fetches a conversation's history of messages and events.
#
# GET /conversations.history
# Docs: https://api.slack.com/methods/conversations.history — API method documentation
# operationId: conversations_history
export def "conversations-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:history` (spec name: token)
  --channel: string # Conversation ID to fetch history for.
  --latest: float # End of time range of messages to include in results.
  --oldest: float # Start of time range of messages to include in results.
  --inclusive: oneof<nothing, bool> # Include messages with latest or oldest timestamp in results only when either timestamp is specified.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record<channel_actions_count: int, channel_actions_ts: list<any>, has_more: bool, messages: table<attachments: list, blocks: list, bot_id: list, bot_profile: record, client_msg_id: string, comment: record, display_as_bot: bool, file: record, files: list, icons: record, inviter: string, is_delayed_message: bool, is_intro: bool, is_starred: bool, last_read: string, latest_reply: string, name: string, old_name: string, parent_user_id: string, permalink: string, pinned_to: list, purpose: string, reactions: list, reply_count: int, reply_users: list, reply_users_count: int, source_team: string, subscribed: bool, subtype: string, team: string, text: string, thread_ts: string, topic: string, ts: string, type: string, unread_count: int, upload: bool, user: string, user_profile: record, user_team: string, username: string>, ok: bool, pin_count: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "latest" $latest "scalar") (serialize-qp "oldest" $oldest "scalar") (serialize-qp "inclusive" $inclusive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.history" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel, "latest": $latest, "oldest": $oldest, "inclusive": $inclusive, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve information about a conversation.
#
# GET /conversations.info
# Docs: https://api.slack.com/methods/conversations.info — API method documentation
# operationId: conversations_info
export def "conversations-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --channel: string # Conversation ID to learn more about
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for this conversation. Defaults to `false`
  --include-num-members: oneof<nothing, bool> # Set to `true` to include the member count for the specified conversation. Defaults to `false`
]: nothing -> oneof<record<channel: list<any>, ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "include_locale" $include_locale "scalar") (serialize-qp "include_num_members" $include_num_members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel, "include_locale": $include_locale, "include_num_members": $include_num_members} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Invites users to a channel.
#
# POST /conversations.invite
# Docs: https://api.slack.com/methods/conversations.invite — API method documentation
# operationId: conversations_invite
export def "conversations-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # The ID of the public or private channel to invite user(s) to.
  --users: string # A comma separated list of user IDs. Up to 1000 users may be listed.
]: any -> oneof<record<channel: list<any>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.invite" $auth.query)
  let req_body = {"channel": $channel, "users": $users} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Joins an existing conversation.
#
# POST /conversations.join
# Docs: https://api.slack.com/methods/conversations.join — API method documentation
# operationId: conversations_join
export def "conversations-join" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `channels:write` (spec name: token)
  --channel: string # ID of conversation to join
]: any -> oneof<record<channel: list<any>, ok: bool, response_metadata: record<warnings: list<string>>, warning: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.join" $auth.query)
  let req_body = {"channel": $channel} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Removes a user from a conversation.
#
# POST /conversations.kick
# Docs: https://api.slack.com/methods/conversations.kick — API method documentation
# operationId: conversations_kick
export def "conversations-kick" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to remove user from.
  --user: string # User ID to be removed.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.kick" $auth.query)
  let req_body = {"channel": $channel, "user": $user} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Leaves a conversation.
#
# POST /conversations.leave
# Docs: https://api.slack.com/methods/conversations.leave — API method documentation
# operationId: conversations_leave
export def "conversations-leave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to leave
]: any -> oneof<record<not_in_channel: bool, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.leave" $auth.query)
  let req_body = {"channel": $channel} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Lists all channels in a Slack team.
#
# GET /conversations.list
# Docs: https://api.slack.com/methods/conversations.list — API method documentation
# operationId: conversations_list
export def "conversations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --exclude-archived: oneof<nothing, bool> # Set to `true` to exclude archived channels from the list
  --types: string # Mix and match channel types by providing a comma-separated list of any combination of `public_channel`, `private_channel`, `mpim`, `im`
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached. Must be an integer no larger than 1000.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "exclude_archived" $exclude_archived "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "exclude_archived": $exclude_archived, "types": $types, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sets the read cursor in a channel.
#
# POST /conversations.mark
# Docs: https://api.slack.com/methods/conversations.mark — API method documentation
# operationId: conversations_mark
export def "conversations-mark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Channel or conversation to set the read cursor for.
  --ts: float # Unique identifier of message you want marked as most recently seen in this conversation.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.mark" $auth.query)
  let req_body = {"channel": $channel, "ts": $ts} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve members of a conversation.
#
# GET /conversations.members
# Docs: https://api.slack.com/methods/conversations.members — API method documentation
# operationId: conversations_members
export def "conversations-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --channel: string # ID of the conversation to retrieve members for
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record<members: list<string>, ok: bool, response_metadata: record<next_cursor: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.members" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Opens or resumes a direct message or multi-person direct message.
#
# POST /conversations.open
# Docs: https://api.slack.com/methods/conversations.open — API method documentation
# operationId: conversations_open
export def "conversations-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Resume a conversation by supplying an `im` or `mpim`'s ID. Or provide the `users` field instead.
  --return-im: oneof<nothing, bool> # Boolean, indicates you want the full IM channel definition in the response.
  --users: string # Comma separated lists of users. If only one user is included, this creates a 1:1 DM. The ordering of the users is preserved whenever a multi-person direct message is returned. Supply a `channel` when not supplying `users`.
]: any -> oneof<record<already_open: bool, channel: list<any>, no_op: bool, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.open" $auth.query)
  let req_body = {"channel": $channel, "return_im": $return_im, "users": $users} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Renames a conversation.
#
# POST /conversations.rename
# Docs: https://api.slack.com/methods/conversations.rename — API method documentation
# operationId: conversations_rename
export def "conversations-rename" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to rename
  --name: string # New name for conversation.
]: any -> oneof<record<channel: list<any>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.rename" $auth.query)
  let req_body = {"channel": $channel, "name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve a thread of messages posted to a conversation
#
# GET /conversations.replies
# Docs: https://api.slack.com/methods/conversations.replies — API method documentation
# operationId: conversations_replies
export def "conversations-replies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:history` (spec name: token)
  --channel: string # Conversation ID to fetch thread from.
  --ts: float # Unique identifier of a thread's parent message. `ts` must be the timestamp of an existing message with 0 or more replies. If there are no replies then just the single message referenced by `ts` will return - it is just an ordinary, unthreaded message.
  --latest: float # End of time range of messages to include in results.
  --oldest: float # Start of time range of messages to include in results.
  --inclusive: oneof<nothing, bool> # Include messages with latest or oldest timestamp in results only when either timestamp is specified.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record<has_more: bool, messages: list<list<any>>, ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "ts" $ts "scalar") (serialize-qp "latest" $latest "scalar") (serialize-qp "oldest" $oldest "scalar") (serialize-qp "inclusive" $inclusive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations.replies" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel, "ts": $ts, "latest": $latest, "oldest": $oldest, "inclusive": $inclusive, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sets the purpose for a conversation.
#
# POST /conversations.setPurpose
# Docs: https://api.slack.com/methods/conversations.setPurpose — API method documentation
# operationId: conversations_setPurpose
export def "conversations-set-purpose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to set the purpose of
  --purpose: string # A new, specialer purpose
]: any -> oneof<record<channel: list<any>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.setPurpose" $auth.query)
  let req_body = {"channel": $channel, "purpose": $purpose} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Sets the topic for a conversation.
#
# POST /conversations.setTopic
# Docs: https://api.slack.com/methods/conversations.setTopic — API method documentation
# operationId: conversations_setTopic
export def "conversations-set-topic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # Conversation to set the topic of
  --topic: string # The new topic string. Does not support formatting or linkification.
]: any -> oneof<record<channel: list<any>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.setTopic" $auth.query)
  let req_body = {"channel": $channel, "topic": $topic} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Reverses conversation archival.
#
# POST /conversations.unarchive
# Docs: https://api.slack.com/methods/conversations.unarchive — API method documentation
# operationId: conversations_unarchive
export def "conversations-unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `conversations:write` (spec name: token)
  --channel: string # ID of conversation to unarchive
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations.unarchive" $auth.query)
  let req_body = {"channel": $channel} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Open a dialog with a user
#
# GET /dialog.open
# Docs: https://api.slack.com/methods/dialog.open — API method documentation
# operationId: dialog_open
export def "dialog-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dialog: string # The dialog definition. This must be a JSON-encoded string. (required)
  --trigger-id: string # Exchange a trigger to post to the user. (required)
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dialog == null) { error make --unspanned { msg: "required query parameter 'dialog' missing: pass --dialog" } }
  if ($trigger_id == null) { error make --unspanned { msg: "required query parameter 'trigger_id' missing: pass --trigger-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "dialog" $dialog "scalar") (serialize-qp "trigger_id" $trigger_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dialog.open" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"dialog": $dialog, "trigger_id": $trigger_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Ends the current user's Do Not Disturb session immediately.
#
# POST /dnd.endDnd
# Docs: https://api.slack.com/methods/dnd.endDnd — API method documentation
# operationId: dnd_endDnd
export def "dnd-end-dnd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `dnd:write` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/dnd.endDnd" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Ends the current user's snooze mode immediately.
#
# POST /dnd.endSnooze
# Docs: https://api.slack.com/methods/dnd.endSnooze — API method documentation
# operationId: dnd_endSnooze
export def "dnd-end-snooze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `dnd:write` (required) (spec name: token)
]: nothing -> oneof<record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/dnd.endSnooze" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Retrieves a user's current Do Not Disturb status.
#
# GET /dnd.info
# Docs: https://api.slack.com/methods/dnd.info — API method documentation
# operationId: dnd_info
export def "dnd-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `dnd:read` (spec name: token)
  --user: string # User to fetch status for (defaults to current user)
]: nothing -> oneof<record<dnd_enabled: bool, next_dnd_end_ts: int, next_dnd_start_ts: int, ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dnd.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Turns on Do Not Disturb mode for the current user, or changes its duration.
#
# POST /dnd.setSnooze
# Docs: https://api.slack.com/methods/dnd.setSnooze — API method documentation
# operationId: dnd_setSnooze
export def "dnd-set-snooze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  num_minutes: string # Number of minutes, from now, to snooze until.
  --body-token: string # Authentication token. Requires scope: `dnd:write` (spec name: token)
]: any -> oneof<record<ok: bool, snooze_enabled: bool, snooze_endtime: int, snooze_remaining: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dnd.setSnooze" $auth.query)
  let req_body = {"num_minutes": $num_minutes, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieves the Do Not Disturb status for up to 50 users on a team.
#
# GET /dnd.teamInfo
# Docs: https://api.slack.com/methods/dnd.teamInfo — API method documentation
# operationId: dnd_teamInfo
export def "dnd-team-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `dnd:read` (spec name: token)
  --users: string # Comma-separated list of users to fetch Do Not Disturb status for
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "users" $users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dnd.teamInfo" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "users": $users} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists custom emoji for a team.
#
# GET /emoji.list
# Docs: https://api.slack.com/methods/emoji.list — API method documentation
# operationId: emoji_list
export def "emoji-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `emoji:read` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emoji.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an existing comment on a file.
#
# POST /files.comments.delete
# Docs: https://api.slack.com/methods/files.comments.delete — API method documentation
# operationId: files_comments_delete
export def "files-comments-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # File to delete a comment from.
  --id: string # The comment to delete.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.comments.delete" $auth.query)
  let req_body = {"file": $file, "id": $id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Deletes a file.
#
# POST /files.delete
# Docs: https://api.slack.com/methods/files.delete — API method documentation
# operationId: files_delete
export def "files-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # ID of file to delete.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.delete" $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Gets information about a file.
#
# GET /files.info
# Docs: https://api.slack.com/methods/files.info — API method documentation
# operationId: files_info
export def "files-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `files:read` (spec name: token)
  --file: string # Specify a file by providing its ID.
  --count: string
  --page: string
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
  --cursor: string # Parameter for pagination. File comments are paginated for a single file. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection of comments. See [pagination](/docs/pagination) for more details.
]: nothing -> oneof<record<comments: list<any>, content_html: any, editor: string, file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "file": $file, "count": $count, "page": $page, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List for a team, in a channel, or from a user with applied filters.
#
# GET /files.list
# Docs: https://api.slack.com/methods/files.list — API method documentation
# operationId: files_list
export def "files-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `files:read` (spec name: token)
  --user: string # Filter files created by a single user.
  --channel: string # Filter files appearing in a specific channel, indicated by its ID.
  --ts-from: float # Filter files created after this timestamp (inclusive).
  --ts-to: float # Filter files created before this timestamp (inclusive).
  --types: string # Filter files by type ([see below](#file_types)). You can pass multiple values in the types argument, like `types=spaces,snippets`.The default value is `all`, which does not filter the list.
  --count: string
  --page: string
  --show-files-hidden-by-limit: oneof<nothing, bool> # Show truncated file info for files hidden due to being too old, and the team who owns the file being over the file limit.
]: nothing -> oneof<record<files: table<channels: list, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list, pretty_type: string, preview: string, public_url_shared: bool, reactions: list, shares: record, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "ts_from" $ts_from "scalar") (serialize-qp "ts_to" $ts_to "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "show_files_hidden_by_limit" $show_files_hidden_by_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "user": $user, "channel": $channel, "ts_from": $ts_from, "ts_to": $ts_to, "types": $types, "count": $count, "page": $page, "show_files_hidden_by_limit": $show_files_hidden_by_limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a file from a remote service
#
# POST /files.remote.add
# Docs: https://api.slack.com/methods/files.remote.add — API method documentation
# operationId: files_remote_add
export def "files-remote-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # Creator defined GUID for the file.
  --external-url: string # URL of the remote file.
  --filetype: string # type of file
  --indexable-file-contents: string # A text file (txt, pdf, doc, etc.) containing textual search terms that are used to improve discovery of the remote file.
  --preview-image: string # Preview of the document via `multipart/form-data`.
  --title: string # Title of the file being shared.
  --body-token: string # Authentication token. Requires scope: `remote_files:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.remote.add" $auth.query)
  let req_body = {"external_id": $external_id, "external_url": $external_url, "filetype": $filetype, "indexable_file_contents": $indexable_file_contents, "preview_image": $preview_image, "title": $title, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve information about a remote file added to Slack
#
# GET /files.remote.info
# Docs: https://api.slack.com/methods/files.remote.info — API method documentation
# operationId: files_remote_info
export def "files-remote-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `remote_files:read` (spec name: token)
  --file: string # Specify a file by providing its ID.
  --external-id: string # Creator defined GUID for the file.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "external_id" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.remote.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "file": $file, "external_id": $external_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve information about a remote file added to Slack
#
# GET /files.remote.list
# Docs: https://api.slack.com/methods/files.remote.list — API method documentation
# operationId: files_remote_list
export def "files-remote-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `remote_files:read` (spec name: token)
  --channel: string # Filter files appearing in a specific channel, indicated by its ID.
  --ts-from: float # Filter files created after this timestamp (inclusive).
  --ts-to: float # Filter files created before this timestamp (inclusive).
  --limit: int # The maximum number of items to return.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "ts_from" $ts_from "scalar") (serialize-qp "ts_to" $ts_to "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.remote.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel, "ts_from": $ts_from, "ts_to": $ts_to, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove a remote file.
#
# POST /files.remote.remove
# Docs: https://api.slack.com/methods/files.remote.remove — API method documentation
# operationId: files_remote_remove
export def "files-remote-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # Creator defined GUID for the file.
  --file: string # Specify a file by providing its ID.
  --body-token: string # Authentication token. Requires scope: `remote_files:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.remote.remove" $auth.query)
  let req_body = {"external_id": $external_id, "file": $file, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Share a remote file into a channel.
#
# GET /files.remote.share
# Docs: https://api.slack.com/methods/files.remote.share — API method documentation
# operationId: files_remote_share
export def "files-remote-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `remote_files:share` (spec name: token)
  --file: string # Specify a file registered with Slack by providing its ID. Either this field or `external_id` or both are required.
  --external-id: string # The globally unique identifier (GUID) for the file, as set by the app registering the file with Slack. Either this field or `file` or both are required.
  --channels: string # Comma-separated list of channel IDs where the file will be shared.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "channels" $channels "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files.remote.share" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "file": $file, "external_id": $external_id, "channels": $channels} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing remote file.
#
# POST /files.remote.update
# Docs: https://api.slack.com/methods/files.remote.update — API method documentation
# operationId: files_remote_update
export def "files-remote-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # Creator defined GUID for the file.
  --external-url: string # URL of the remote file.
  --file: string # Specify a file by providing its ID.
  --filetype: string # type of file
  --indexable-file-contents: string # File containing contents that can be used to improve searchability for the remote file.
  --preview-image: string # Preview of the document via `multipart/form-data`.
  --title: string # Title of the file being shared.
  --body-token: string # Authentication token. Requires scope: `remote_files:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.remote.update" $auth.query)
  let req_body = {"external_id": $external_id, "external_url": $external_url, "file": $file, "filetype": $filetype, "indexable_file_contents": $indexable_file_contents, "preview_image": $preview_image, "title": $title, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Revokes public/external sharing access for a file
#
# POST /files.revokePublicURL
# Docs: https://api.slack.com/methods/files.revokePublicURL — API method documentation
# operationId: files_revokePublicURL
export def "files-revoke-public-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # File to revoke
]: any -> oneof<record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.revokePublicURL" $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Enables a file for public/external sharing.
#
# POST /files.sharedPublicURL
# Docs: https://api.slack.com/methods/files.sharedPublicURL — API method documentation
# operationId: files_sharedPublicURL
export def "files-shared-public-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
  --file: string # File to share
]: any -> oneof<record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.sharedPublicURL" $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Uploads or creates a file.
#
# POST /files.upload
# Docs: https://api.slack.com/methods/files.upload — API method documentation
# operationId: files_upload
export def "files-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channels: string # Comma-separated list of channel names or IDs where the file will be shared.
  --content: string # File contents via a POST variable. If omitting this parameter, you must provide a `file`.
  --file: string # File contents via `multipart/form-data`. If omitting this parameter, you must submit `content`.
  --filename: string # Filename of file.
  --filetype: string # A [file type](/types/file#file_types) identifier.
  --initial-comment: string # The message text introducing the file in specified `channels`.
  --thread-ts: float # Provide another message's `ts` value to upload this file as a reply. Never use a reply's `ts` value; use its parent instead.
  --title: string # Title of file.
  --body-token: string # Authentication token. Requires scope: `files:write:user` (spec name: token)
]: any -> oneof<record<file: record<channels: list<string>, comments_count: int, created: int, date_delete: int, display_as_bot: bool, editable: bool, editor: string, external_id: string, external_type: string, external_url: string, filetype: string, groups: list<string>, has_rich_preview: bool, id: string, image_exif_rotation: int, ims: list<string>, is_external: bool, is_public: bool, is_starred: bool, is_tombstoned: bool, last_editor: string, mimetype: string, mode: string, name: string, non_owner_editable: bool, num_stars: int, original_h: int, original_w: int, permalink: string, permalink_public: string, pinned_info: record, pinned_to: list<string>, pretty_type: string, preview: string, public_url_shared: bool, reactions: list<record>, shares: record<private: any, public: any>, size: int, source_team: string, state: string, thumb_1024: string, thumb_1024_h: int, thumb_1024_w: int, thumb_160: string, thumb_360: string, thumb_360_h: int, thumb_360_w: int, thumb_480: string, thumb_480_h: int, thumb_480_w: int, thumb_64: string, thumb_720: string, thumb_720_h: int, thumb_720_w: int, thumb_80: string, thumb_800: string, thumb_800_h: int, thumb_800_w: int, thumb_960: string, thumb_960_h: int, thumb_960_w: int, thumb_tiny: string, timestamp: int, title: string, updated: int, url_private: string, url_private_download: string, user: string, user_team: string, username: string>, ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files.upload" $auth.query)
  let req_body = {"channels": $channels, "content": $content, "file": $file, "filename": $filename, "filetype": $filetype, "initial_comment": $initial_comment, "thread_ts": $thread_ts, "title": $title, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# For Enterprise Grid workspaces, map local user IDs to global user IDs
#
# GET /migration.exchange
# Docs: https://api.slack.com/methods/migration.exchange — API method documentation
# operationId: migration_exchange
export def "migration-exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `tokens.basic` (required) (spec name: token)
  --users: string # A comma-separated list of user ids, up to 400 per request (required)
  --team-id: string # Specify team_id starts with `T` in case of Org Token
  --to-old: oneof<nothing, bool> # Specify `true` to convert `W` global user IDs to workspace-specific `U` IDs. Defaults to `false`.
]: nothing -> oneof<record<enterprise_id: string, invalid_user_ids: list<string>, ok: bool, team_id: string, user_id_map: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($users == null) { error make --unspanned { msg: "required query parameter 'users' missing: pass --users" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "to_old" $to_old "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/migration.exchange" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "users": $users, "team_id": $team_id, "to_old": $to_old} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Exchanges a temporary OAuth verifier code for an access token.
#
# GET /oauth.access
# Docs: https://api.slack.com/methods/oauth.access — API method documentation
# operationId: oauth_access
export def "oauth-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback.
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
  --single-channel: oneof<nothing, bool> # Request the user to add your app only to a single channel. Only valid with a [legacy workspace app](https://api.slack.com/legacy-workspace-apps).
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "single_channel" $single_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth.access" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"client_id": $client_id, "client_secret": $client_secret, "code": $code, "redirect_uri": $redirect_uri, "single_channel": $single_channel} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Exchanges a temporary OAuth verifier code for a workspace token.
#
# GET /oauth.token
# Docs: https://api.slack.com/methods/oauth.token — API method documentation
# operationId: oauth_token
export def "oauth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback.
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
  --single-channel: oneof<nothing, bool> # Request the user to add your app only to a single channel.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "single_channel" $single_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth.token" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"client_id": $client_id, "client_secret": $client_secret, "code": $code, "redirect_uri": $redirect_uri, "single_channel": $single_channel} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Exchanges a temporary OAuth verifier code for an access token.
#
# GET /oauth.v2.access
# Docs: https://api.slack.com/methods/oauth.v2.access — API method documentation
# operationId: oauth_v2_access
export def "oauth-v2-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Issued when you created your application.
  --client-secret: string # Issued when you created your application.
  --code: string # The `code` param returned via the OAuth callback. (required)
  --redirect-uri: string # This must match the originally submitted URI (if one was sent).
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($code == null) { error make --unspanned { msg: "required query parameter 'code' missing: pass --code" } }
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth.v2.access" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"client_id": $client_id, "client_secret": $client_secret, "code": $code, "redirect_uri": $redirect_uri} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Pins an item to a channel.
#
# POST /pins.add
# Docs: https://api.slack.com/methods/pins.add — API method documentation
# operationId: pins_add
export def "pins-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `pins:write` (required) (spec name: token)
  channel: string # Channel to pin the item in.
  --timestamp: string # Timestamp of the message to pin.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/pins.add" $auth.query)
  let req_body = {"channel": $channel, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Lists items pinned to a channel.
#
# GET /pins.list
# Docs: https://api.slack.com/methods/pins.list — API method documentation
# operationId: pins_list
export def "pins-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `pins:read` (required) (spec name: token)
  --channel: string # Channel to get pinned items for. (required)
]: nothing -> oneof<list<any>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($channel == null) { error make --unspanned { msg: "required query parameter 'channel' missing: pass --channel" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pins.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Un-pins an item from a channel.
#
# POST /pins.remove
# Docs: https://api.slack.com/methods/pins.remove — API method documentation
# operationId: pins_remove
export def "pins-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `pins:write` (required) (spec name: token)
  channel: string # Channel where the item is pinned to.
  --timestamp: string # Timestamp of the message to un-pin.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/pins.remove" $auth.query)
  let req_body = {"channel": $channel, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Adds a reaction to an item.
#
# POST /reactions.add
# Docs: https://api.slack.com/methods/reactions.add — API method documentation
# operationId: reactions_add
export def "reactions-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reactions:write` (required) (spec name: token)
  channel: string # Channel where the message to add reaction to was posted.
  name: string # Reaction (emoji) name.
  timestamp: string # Timestamp of the message to add reaction to.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/reactions.add" $auth.query)
  let req_body = {"channel": $channel, "name": $name, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Gets reactions for an item.
#
# GET /reactions.get
# Docs: https://api.slack.com/methods/reactions.get — API method documentation
# operationId: reactions_get
export def "reactions-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reactions:read` (required) (spec name: token)
  --channel: string # Channel where the message to get reactions for was posted.
  --file: string # File to get reactions for.
  --file-comment: string # File comment to get reactions for.
  --qp-full: oneof<nothing, bool> # If true always return the complete reaction list. (spec name: full)
  --timestamp: string # Timestamp of the message to get reactions for.
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "file" $file "scalar") (serialize-qp "file_comment" $file_comment "scalar") (serialize-qp "full" $qp_full "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reactions.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "channel": $channel, "file": $file, "file_comment": $file_comment, "full": $qp_full, "timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists reactions made by a user.
#
# GET /reactions.list
# Docs: https://api.slack.com/methods/reactions.list — API method documentation
# operationId: reactions_list
export def "reactions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reactions:read` (required) (spec name: token)
  --user: string # Show reactions made by this user. Defaults to the authed user.
  --qp-full: oneof<nothing, bool> # If true always return the complete reaction list. (spec name: full)
  --count: int
  --page: int
  --cursor: string # Parameter for pagination. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection. See [pagination](/docs/pagination) for more details.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
]: nothing -> oneof<record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>, response_metadata: list<any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "full" $qp_full "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reactions.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "user": $user, "full": $qp_full, "count": $count, "page": $page, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes a reaction from an item.
#
# POST /reactions.remove
# Docs: https://api.slack.com/methods/reactions.remove — API method documentation
# operationId: reactions_remove
export def "reactions-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reactions:write` (required) (spec name: token)
  --channel: string # Channel where the message to remove reaction from was posted.
  --file: string # File to remove reaction from.
  --file-comment: string # File comment to remove reaction from.
  name: string # Reaction (emoji) name.
  --timestamp: string # Timestamp of the message to remove reaction from.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/reactions.remove" $auth.query)
  let req_body = {"channel": $channel, "file": $file, "file_comment": $file_comment, "name": $name, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Creates a reminder.
#
# POST /reminders.add
# Docs: https://api.slack.com/methods/reminders.add — API method documentation
# operationId: reminders_add
export def "reminders-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reminders:write` (required) (spec name: token)
  text: string # The content of the reminder
  time: string # When this reminder should happen: the Unix timestamp (up to five years from now), the number of seconds until the reminder (if within 24 hours), or a natural language description (Ex. "in 15 minutes," or "every Thursday")
  --user: string # The user who will receive the reminder. If no user is specified, the reminder will go to user who created it.
]: any -> oneof<record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/reminders.add" $auth.query)
  let req_body = {"text": $text, "time": $time, "user": $user} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Marks a reminder as complete.
#
# POST /reminders.complete
# Docs: https://api.slack.com/methods/reminders.complete — API method documentation
# operationId: reminders_complete
export def "reminders-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reminders:write` (spec name: token)
  --reminder: string # The ID of the reminder to be marked as complete
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reminders.complete" $auth.query)
  let req_body = {"reminder": $reminder} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Deletes a reminder.
#
# POST /reminders.delete
# Docs: https://api.slack.com/methods/reminders.delete — API method documentation
# operationId: reminders_delete
export def "reminders-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `reminders:write` (spec name: token)
  --reminder: string # The ID of the reminder
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reminders.delete" $auth.query)
  let req_body = {"reminder": $reminder} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Gets information about a reminder.
#
# GET /reminders.info
# Docs: https://api.slack.com/methods/reminders.info — API method documentation
# operationId: reminders_info
export def "reminders-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reminders:read` (spec name: token)
  --reminder: string # The ID of the reminder
]: nothing -> oneof<record<ok: bool, reminder: record<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "reminder" $reminder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reminders.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "reminder": $reminder} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all reminders created by or for a given user.
#
# GET /reminders.list
# Docs: https://api.slack.com/methods/reminders.list — API method documentation
# operationId: reminders_list
export def "reminders-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `reminders:read` (spec name: token)
]: nothing -> oneof<record<ok: bool, reminders: table<complete_ts: int, creator: string, id: string, recurring: bool, text: string, time: int, user: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reminders.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Starts a Real Time Messaging session.
#
# GET /rtm.connect
# Docs: https://api.slack.com/methods/rtm.connect — API method documentation
# operationId: rtm_connect
export def "rtm-connect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `rtm:stream` (required) (spec name: token)
  --batch-presence-aware: oneof<nothing, bool> # Batch presence deliveries via subscription. Enabling changes the shape of `presence_change` events. See [batch presence](/docs/presence-and-status#batching).
  --presence-sub: oneof<nothing, bool> # Only deliver presence events when requested by subscription. See [presence subscriptions](/docs/presence-and-status#subscriptions).
]: nothing -> oneof<record<ok: bool, self: record<id: string, name: string>, team: record<domain: string, id: string, name: string>, url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "batch_presence_aware" $batch_presence_aware "scalar") (serialize-qp "presence_sub" $presence_sub "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rtm.connect" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "batch_presence_aware": $batch_presence_aware, "presence_sub": $presence_sub} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Searches for messages matching a query.
#
# GET /search.messages
# Docs: https://api.slack.com/methods/search.messages — API method documentation
# operationId: search_messages
export def "search-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `search:read` (required) (spec name: token)
  --count: int # Pass the number of results you want per "page". Maximum of `100`.
  --highlight: oneof<nothing, bool> # Pass a value of `true` to enable query highlight markers (see below).
  --page: int
  --query: string # Search query. (required)
  --sort: string # Return matches sorted by either `score` or `timestamp`.
  --sort-dir: string # Change sort direction to ascending (`asc`) or descending (`desc`).
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($query == null) { error make --unspanned { msg: "required query parameter 'query' missing: pass --query" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "highlight" $highlight "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $sort "scalar") (serialize-qp "sort_dir" $sort_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search.messages" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "count": $count, "highlight": $highlight, "page": $page, "query": $query, "sort": $sort, "sort_dir": $sort_dir} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a star to an item.
#
# POST /stars.add
# Docs: https://api.slack.com/methods/stars.add — API method documentation
# operationId: stars_add
export def "stars-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `stars:write` (required) (spec name: token)
  --channel: string # Channel to add star to, or channel where the message to add star to was posted (used with `timestamp`).
  --file: string # File to add star to.
  --file-comment: string # File comment to add star to.
  --timestamp: string # Timestamp of the message to add star to.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/stars.add" $auth.query)
  let req_body = {"channel": $channel, "file": $file, "file_comment": $file_comment, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Lists stars for a user.
#
# GET /stars.list
# Docs: https://api.slack.com/methods/stars.list — API method documentation
# operationId: stars_list
export def "stars-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `stars:read` (spec name: token)
  --count: string
  --page: string
  --cursor: string # Parameter for pagination. Set `cursor` equal to the `next_cursor` attribute returned by the previous request's `response_metadata`. This parameter is optional, but pagination is mandatory: the default value simply fetches the first "page" of the collection. See [pagination](/docs/pagination) for more details.
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached.
]: nothing -> oneof<record<items: list<list<any>>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stars.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "count": $count, "page": $page, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes a star from an item.
#
# POST /stars.remove
# Docs: https://api.slack.com/methods/stars.remove — API method documentation
# operationId: stars_remove
export def "stars-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `stars:write` (required) (spec name: token)
  --channel: string # Channel to remove star from, or channel where the message to remove star from was posted (used with `timestamp`).
  --file: string # File to remove star from.
  --file-comment: string # File comment to remove star from.
  --timestamp: string # Timestamp of the message to remove star from.
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/stars.remove" $auth.query)
  let req_body = {"channel": $channel, "file": $file, "file_comment": $file_comment, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Gets the access logs for the current team.
#
# GET /team.accessLogs
# Docs: https://api.slack.com/methods/team.accessLogs — API method documentation
# operationId: team_accessLogs
export def "team-access-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin` (required) (spec name: token)
  --before: string # End of time range of logs to include in results (inclusive).
  --count: string
  --page: string
]: nothing -> oneof<record<logins: table<count: int, country: string, date_first: int, date_last: int, ip: string, isp: string, region: string, user_agent: string, user_id: string, username: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.accessLogs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "before": $before, "count": $count, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets billable users information for the current team.
#
# GET /team.billableInfo
# Docs: https://api.slack.com/methods/team.billableInfo — API method documentation
# operationId: team_billableInfo
export def "team-billable-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin` (required) (spec name: token)
  --user: string # A user to retrieve the billable information for. Defaults to all users.
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.billableInfo" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets information about the current team.
#
# GET /team.info
# Docs: https://api.slack.com/methods/team.info — API method documentation
# operationId: team_info
export def "team-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `team:read` (required) (spec name: token)
  --team: string # Team to get info on, if omitted, will return information about the current team. Will only return team that the authenticated token is allowed to see through external shared channels
]: nothing -> oneof<record<ok: bool, team: record<archived: bool, avatar_base_url: string, created: int, date_create: int, deleted: bool, description: string, discoverable: list<any>, domain: string, email_domain: string, enterprise_id: string, enterprise_name: string, external_org_migrations: record<current: list, date_updated: int>, has_compliance_export: bool, icon: record<image_102: string, image_132: string, image_230: string, image_34: string, image_44: string, image_68: string, image_88: string, image_default: bool>, id: string, is_assigned: bool, is_enterprise: int, is_over_storage_limit: bool, limit_ts: int, locale: string, messages_count: int, msg_edit_window_mins: int, name: string, over_integrations_limit: bool, over_storage_limit: bool, pay_prod_cur: string, plan: string, primary_owner: record<email: string, id: string>, sso_provider: record<label: string, name: string, type: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "team" $team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "team": $team} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the integration logs for the current team.
#
# GET /team.integrationLogs
# Docs: https://api.slack.com/methods/team.integrationLogs — API method documentation
# operationId: team_integrationLogs
export def "team-integration-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `admin` (required) (spec name: token)
  --app-id: string # Filter logs to this Slack app. Defaults to all logs.
  --change-type: string # Filter logs with this change type. Defaults to all logs.
  --count: string
  --page: string
  --service-id: string # Filter logs to this service. Defaults to all logs.
  --user: string # Filter logs generated by this user’s actions. Defaults to all logs.
]: nothing -> oneof<record<logs: table<admin_app_id: string, app_id: string, app_type: string, change_type: string, channel: string, date: string, scope: string, service_id: string, service_type: string, user_id: string, user_name: string>, ok: bool, paging: record<count: int, page: int, pages: int, per_page: int, spill: int, total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "app_id" $app_id "scalar") (serialize-qp "change_type" $change_type "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.integrationLogs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "app_id": $app_id, "change_type": $change_type, "count": $count, "page": $page, "service_id": $service_id, "user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a team's profile.
#
# GET /team.profile.get
# Docs: https://api.slack.com/methods/team.profile.get — API method documentation
# operationId: team_profile_get
export def "team-profile-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users.profile:read` (required) (spec name: token)
  --visibility: string # Filter by visibility.
]: nothing -> oneof<record<ok: bool, profile: record<fields: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team.profile.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "visibility": $visibility} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a User Group
#
# POST /usergroups.create
# Docs: https://api.slack.com/methods/usergroups.create — API method documentation
# operationId: usergroups_create
export def "usergroups-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --channels: string # A comma separated string of encoded channel IDs for which the User Group uses as a default.
  --description: string # A short description of the User Group.
  --handle: string # A mention handle. Must be unique among channels, users and User Groups.
  --include-count: oneof<nothing, bool> # Include the number of users in each User Group.
  name: string # A name for the User Group. Must be unique among User Groups.
]: any -> oneof<record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/usergroups.create" $auth.query)
  let req_body = {"channels": $channels, "description": $description, "handle": $handle, "include_count": $include_count, "name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Disable an existing User Group
#
# POST /usergroups.disable
# Docs: https://api.slack.com/methods/usergroups.disable — API method documentation
# operationId: usergroups_disable
export def "usergroups-disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to disable.
]: any -> oneof<record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/usergroups.disable" $auth.query)
  let req_body = {"include_count": $include_count, "usergroup": $usergroup} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Enable a User Group
#
# POST /usergroups.enable
# Docs: https://api.slack.com/methods/usergroups.enable — API method documentation
# operationId: usergroups_enable
export def "usergroups-enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to enable.
]: any -> oneof<record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/usergroups.enable" $auth.query)
  let req_body = {"include_count": $include_count, "usergroup": $usergroup} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all User Groups for a team
#
# GET /usergroups.list
# Docs: https://api.slack.com/methods/usergroups.list — API method documentation
# operationId: usergroups_list
export def "usergroups-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-users: oneof<nothing, bool> # Include the list of users for each User Group.
  --qp-token: string # Authentication token. Requires scope: `usergroups:read` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in each User Group.
  --include-disabled: oneof<nothing, bool> # Include disabled User Groups.
]: nothing -> oneof<record<ok: bool, usergroups: table<auto_provision: bool, auto_type: list, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record, team_id: string, updated_by: string, user_count: int, users: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "include_users" $include_users "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "include_count" $include_count "scalar") (serialize-qp "include_disabled" $include_disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usergroups.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_users": $include_users, "token": $qp_token, "include_count": $include_count, "include_disabled": $include_disabled} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing User Group
#
# POST /usergroups.update
# Docs: https://api.slack.com/methods/usergroups.update — API method documentation
# operationId: usergroups_update
export def "usergroups-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --channels: string # A comma separated string of encoded channel IDs for which the User Group uses as a default.
  --description: string # A short description of the User Group.
  --handle: string # A mention handle. Must be unique among channels, users and User Groups.
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  --name: string # A name for the User Group. Must be unique among User Groups.
  usergroup: string # The encoded ID of the User Group to update.
]: any -> oneof<record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/usergroups.update" $auth.query)
  let req_body = {"channels": $channels, "description": $description, "handle": $handle, "include_count": $include_count, "name": $name, "usergroup": $usergroup} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List all users in a User Group
#
# GET /usergroups.users.list
# Docs: https://api.slack.com/methods/usergroups.users.list — API method documentation
# operationId: usergroups_users_list
export def "usergroups-users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `usergroups:read` (required) (spec name: token)
  --include-disabled: oneof<nothing, bool> # Allow results that involve disabled User Groups.
  --usergroup: string # The encoded ID of the User Group to update. (required)
]: nothing -> oneof<record<ok: bool, users: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($usergroup == null) { error make --unspanned { msg: "required query parameter 'usergroup' missing: pass --usergroup" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "include_disabled" $include_disabled "scalar") (serialize-qp "usergroup" $usergroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usergroups.users.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "include_disabled": $include_disabled, "usergroup": $usergroup} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the list of users for a User Group
#
# POST /usergroups.users.update
# Docs: https://api.slack.com/methods/usergroups.users.update — API method documentation
# operationId: usergroups_users_update
export def "usergroups-users-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `usergroups:write` (required) (spec name: token)
  --include-count: oneof<nothing, bool> # Include the number of users in the User Group.
  usergroup: string # The encoded ID of the User Group to update.
  users: string # A comma separated string of encoded user IDs that represent the entire list of users for the User Group.
]: any -> oneof<record<ok: bool, usergroup: record<auto_provision: bool, auto_type: list<any>, channel_count: int, created_by: string, date_create: int, date_delete: int, date_update: int, deleted_by: list<any>, description: string, enterprise_subteam_id: string, handle: string, id: string, is_external: bool, is_subteam: bool, is_usergroup: bool, name: string, prefs: record<channels: list, groups: list>, team_id: string, updated_by: string, user_count: int, users: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/usergroups.users.update" $auth.query)
  let req_body = {"include_count": $include_count, "usergroup": $usergroup, "users": $users} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# List conversations the calling user may access.
#
# GET /users.conversations
# Docs: https://api.slack.com/methods/users.conversations — API method documentation
# operationId: users_conversations
export def "users-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `conversations:read` (spec name: token)
  --user: string # Browse conversations by a specific user ID's membership. Non-public channels are restricted to those where the calling user shares membership.
  --types: string # Mix and match channel types by providing a comma-separated list of any combination of `public_channel`, `private_channel`, `mpim`, `im`
  --exclude-archived: oneof<nothing, bool> # Set to `true` to exclude archived channels from the list
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the list hasn't been reached. Must be an integer no larger than 1000.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
]: nothing -> oneof<record<channels: list<list<any>>, ok: bool, response_metadata: record<next_cursor: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "exclude_archived" $exclude_archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.conversations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "user": $user, "types": $types, "exclude_archived": $exclude_archived, "limit": $limit, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete the user profile photo
#
# POST /users.deletePhoto
# Docs: https://api.slack.com/methods/users.deletePhoto — API method documentation
# operationId: users_deletePhoto
export def "users-delete-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token. Requires scope: `users.profile:write` (spec name: token)
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.deletePhoto" $auth.query)
  let req_body = {"token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Gets user presence information.
#
# GET /users.getPresence
# Docs: https://api.slack.com/methods/users.getPresence — API method documentation
# operationId: users_getPresence
export def "users-get-presence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (required) (spec name: token)
  --user: string # User to get presence info on. Defaults to the authed user.
]: nothing -> oneof<record<auto_away: bool, connection_count: int, last_activity: int, manual_away: bool, ok: bool, online: bool, presence: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.getPresence" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a user's identity.
#
# GET /users.identity
# Docs: https://api.slack.com/methods/users.identity — API method documentation
# operationId: users_identity
export def "users-identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `identity.basic` (spec name: token)
]: nothing -> oneof<list<any>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.identity" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets information about a user.
#
# GET /users.info
# Docs: https://api.slack.com/methods/users.info — API method documentation
# operationId: users_info
export def "users-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (required) (spec name: token)
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for this user. Defaults to `false`
  --user: string # User to get info on
]: nothing -> oneof<record<ok: bool, user: list<any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "include_locale" $include_locale "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "include_locale": $include_locale, "user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all users in a Slack team.
#
# GET /users.list
# Docs: https://api.slack.com/methods/users.list — API method documentation
# operationId: users_list
export def "users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read` (spec name: token)
  --limit: int # The maximum number of items to return. Fewer than the requested number of items may be returned, even if the end of the users list hasn't been reached. Providing no `limit` value will result in Slack attempting to deliver you the entire result set. If the collection is too large you may experience `limit_required` or HTTP 500 errors.
  --cursor: string # Paginate through collections of data by setting the `cursor` parameter to a `next_cursor` attribute returned by a previous request's `response_metadata`. Default value fetches the first "page" of the collection. See [pagination](/docs/pagination) for more detail.
  --include-locale: oneof<nothing, bool> # Set this to `true` to receive the locale for users. Defaults to `false`
]: nothing -> oneof<record<cache_ts: int, members: list<list<any>>, ok: bool, response_metadata: list<any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "include_locale" $include_locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "limit": $limit, "cursor": $cursor, "include_locale": $include_locale} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find a user with an email address.
#
# GET /users.lookupByEmail
# Docs: https://api.slack.com/methods/users.lookupByEmail — API method documentation
# operationId: users_lookupByEmail
export def "users-lookup-by-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users:read.email` (required) (spec name: token)
  --email: string # An email address belonging to a user in the workspace (required)
]: nothing -> oneof<record<ok: bool, user: list<any>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  if ($email == null) { error make --unspanned { msg: "required query parameter 'email' missing: pass --email" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.lookupByEmail" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "email": $email} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves a user's profile information.
#
# GET /users.profile.get
# Docs: https://api.slack.com/methods/users.profile.get — API method documentation
# operationId: users_profile_get
export def "users-profile-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Authentication token. Requires scope: `users.profile:read` (required) (spec name: token)
  --include-labels: oneof<nothing, bool> # Include labels for each ID in custom profile fields
  --user: string # User to retrieve profile info for
]: nothing -> oneof<record<ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: list<record>, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($qp_token == null) { error make --unspanned { msg: "required query parameter 'token' missing: pass --qp-token" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "include_labels" $include_labels "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users.profile.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "include_labels": $include_labels, "user": $user} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Set the profile information for a user.
#
# POST /users.profile.set
# Docs: https://api.slack.com/methods/users.profile.set — API method documentation
# operationId: users_profile_set
export def "users-profile-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `users.profile:write` (required) (spec name: token)
  --name: string # Name of a single key to set. Usable only if `profile` is not passed.
  --profile: string # Collection of key:value pairs presented as a URL-encoded JSON hash. At most 50 fields may be set. Each field name is limited to 255 characters.
  --user: string # ID of user to change. This argument may only be specified by team admins on paid teams.
  --value: string # Value to set a single key to. Usable only if `profile` is not passed.
]: any -> oneof<record<email_pending: string, ok: bool, profile: record<always_active: bool, api_app_id: string, avatar_hash: string, bot_id: string, display_name: string, display_name_normalized: string, email: string, fields: list<record>, first_name: string, guest_expiration_ts: int, guest_invited_by: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string, is_app_user: bool, is_custom_image: bool, is_restricted: bool, is_ultra_restricted: bool, last_avatar_image_hash: string, last_name: string, memberships_count: int, name: string, phone: string, pronouns: string, real_name: string, real_name_normalized: string, skype: string, status_default_emoji: string, status_default_text: string, status_default_text_canonical: string, status_emoji: string, status_expiration: int, status_text: string, status_text_canonical: string, team: string, title: string, updated: int, user_id: string, username: string>, username: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/users.profile.set" $auth.query)
  let req_body = {"name": $name, "profile": $profile, "user": $user, "value": $value} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Marked a user as active. Deprecated and non-functional.
#
# POST /users.setActive
# Docs: https://api.slack.com/methods/users.setActive — API method documentation
# operationId: users_setActive
export def "users-set-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `users:write` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/users.setActive" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Set the user profile photo
#
# POST /users.setPhoto
# Docs: https://api.slack.com/methods/users.setPhoto — API method documentation
# operationId: users_setPhoto
export def "users-set-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --crop-w: string # Width/height of crop box (always square)
  --crop-x: string # X coordinate of top-left corner of crop box
  --crop-y: string # Y coordinate of top-left corner of crop box
  --image: string # File contents via `multipart/form-data`.
  --body-token: string # Authentication token. Requires scope: `users.profile:write` (spec name: token)
]: any -> oneof<record<ok: bool, profile: record<avatar_hash: string, image_1024: string, image_192: string, image_24: string, image_32: string, image_48: string, image_512: string, image_72: string, image_original: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.setPhoto" $auth.query)
  let req_body = {"crop_w": $crop_w, "crop_x": $crop_x, "crop_y": $crop_y, "image": $image, "token": $body_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Manually sets user presence.
#
# POST /users.setPresence
# Docs: https://api.slack.com/methods/users.setPresence — API method documentation
# operationId: users_setPresence
export def "users-set-presence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # Authentication token. Requires scope: `users:write` (required) (spec name: token)
  presence: string # Either `auto` or `away`
]: any -> oneof<record<ok: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let full_url = (build-url $base "/users.setPresence" $auth.query)
  let req_body = {"presence": $presence} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Open a view for a user.
#
# GET /views.open
# Docs: https://api.slack.com/methods/views.open — API method documentation
# operationId: views_open
export def "views-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trigger-id: string # Exchange a trigger to post to the user. (required)
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string. (required)
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($trigger_id == null) { error make --unspanned { msg: "required query parameter 'trigger_id' missing: pass --trigger-id" } }
  if ($view == null) { error make --unspanned { msg: "required query parameter 'view' missing: pass --view" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "trigger_id" $trigger_id "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.open" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"trigger_id": $trigger_id, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Publish a static view for a User.
#
# GET /views.publish
# Docs: https://api.slack.com/methods/views.publish — API method documentation
# operationId: views_publish
export def "views-publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # `id` of the user you want publish a view to. (required)
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string. (required)
  --hash: string # A string that represents view state to protect against possible race conditions.
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id == null) { error make --unspanned { msg: "required query parameter 'user_id' missing: pass --user-id" } }
  if ($view == null) { error make --unspanned { msg: "required query parameter 'view' missing: pass --view" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.publish" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user_id": $user_id, "view": $view, "hash": $hash} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Push a view onto the stack of a root view.
#
# GET /views.push
# Docs: https://api.slack.com/methods/views.push — API method documentation
# operationId: views_push
export def "views-push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trigger-id: string # Exchange a trigger to post to the user. (required)
  --view: string # A [view payload](/reference/surfaces/views). This must be a JSON-encoded string. (required)
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($trigger_id == null) { error make --unspanned { msg: "required query parameter 'trigger_id' missing: pass --trigger-id" } }
  if ($view == null) { error make --unspanned { msg: "required query parameter 'view' missing: pass --view" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "trigger_id" $trigger_id "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.push" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"trigger_id": $trigger_id, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing view.
#
# GET /views.update
# Docs: https://api.slack.com/methods/views.update — API method documentation
# operationId: views_update
export def "views-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: string # A unique identifier of the view to be updated. Either `view_id` or `external_id` is required.
  --external-id: string # A unique identifier of the view set by the developer. Must be unique for all views on a team. Max length of 255 characters. Either `view_id` or `external_id` is required.
  --view: string # A [view object](/reference/surfaces/views). This must be a JSON-encoded string.
  --hash: string # A string that represents view state to protect against possible race conditions.
  --hdr-token: string # Authentication token. Requires scope: `none` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "view_id" $view_id "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/views.update" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"view_id": $view_id, "external_id": $external_id, "view": $view, "hash": $hash} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Indicate that an app's step in a workflow completed execution.
#
# GET /workflows.stepCompleted
# Docs: https://api.slack.com/methods/workflows.stepCompleted — API method documentation
# operationId: workflows_stepCompleted
export def "workflows-step-completed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-step-execute-id: string # Context identifier that maps to the correct workflow step execution. (required)
  --outputs: string # Key-value object of outputs from your step. Keys of this object reflect the configured `key` properties of your [`outputs`](/reference/workflows/workflow_step#output) array from your `workflow_step` object.
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workflow_step_execute_id == null) { error make --unspanned { msg: "required query parameter 'workflow_step_execute_id' missing: pass --workflow-step-execute-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "workflow_step_execute_id" $workflow_step_execute_id "scalar") (serialize-qp "outputs" $outputs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows.stepCompleted" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"workflow_step_execute_id": $workflow_step_execute_id, "outputs": $outputs} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Indicate that an app's step in a workflow failed to execute.
#
# GET /workflows.stepFailed
# Docs: https://api.slack.com/methods/workflows.stepFailed — API method documentation
# operationId: workflows_stepFailed
export def "workflows-step-failed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-step-execute-id: string # Context identifier that maps to the correct workflow step execution. (required)
  --error: string # A JSON-based object with a `message` property that should contain a human readable error message. (required)
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workflow_step_execute_id == null) { error make --unspanned { msg: "required query parameter 'workflow_step_execute_id' missing: pass --workflow-step-execute-id" } }
  if ($error == null) { error make --unspanned { msg: "required query parameter 'error' missing: pass --error" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "workflow_step_execute_id" $workflow_step_execute_id "scalar") (serialize-qp "error" $error "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows.stepFailed" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"workflow_step_execute_id": $workflow_step_execute_id, "error": $error} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the configuration for a workflow extension step.
#
# GET /workflows.updateStep
# Docs: https://api.slack.com/methods/workflows.updateStep — API method documentation
# operationId: workflows_updateStep
export def "workflows-update-step" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-step-edit-id: string # A context identifier provided with `view_submission` payloads used to call back to `workflows.updateStep`. (required)
  --inputs: string # A JSON key-value map of inputs required from a user during configuration. This is the data your app expects to receive when the workflow step starts. **Please note**: the embedded variable format is set and replaced by the workflow system. You cannot create custom variables that will be replaced at runtime. [Read more about variables in workflow steps here](/workflows/steps#variables).
  --outputs: string # An JSON array of output objects used during step execution. This is the data your app agrees to provide when your workflow step was executed.
  --step-name: string # An optional field that can be used to override the step name that is shown in the Workflow Builder.
  --step-image-url: string # An optional field that can be used to override app image that is shown in the Workflow Builder.
  --hdr-token: string # Authentication token. Requires scope: `workflow.steps:execute` (required) (spec name: token)
]: nothing -> oneof<record<ok: bool>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workflow_step_edit_id == null) { error make --unspanned { msg: "required query parameter 'workflow_step_edit_id' missing: pass --workflow-step-edit-id" } }
  if ($hdr_token == null) { error make --unspanned { msg: "required header parameter 'token' missing: pass --hdr-token" } }
  let qp = [(serialize-qp "workflow_step_edit_id" $workflow_step_edit_id "scalar") (serialize-qp "inputs" $inputs "scalar") (serialize-qp "outputs" $outputs "scalar") (serialize-qp "step_name" $step_name "scalar") (serialize-qp "step_image_url" $step_image_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows.updateStep" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"token": $hdr_token} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"workflow_step_edit_id": $workflow_step_edit_id, "inputs": $inputs, "outputs": $outputs, "step_name": $step_name, "step_image_url": $step_image_url} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
