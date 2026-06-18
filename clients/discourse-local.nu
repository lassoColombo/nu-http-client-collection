# Auto-generated client for Discourse API Documentation vlatest
# Source: https://api.apis.guru/v2/specs/discourse.local/latest/openapi.json
# Auth: --token flag or $env.DISCOURSE_API_DOCUMENTATION_TOKEN

const BASE_URL = "http://discourse.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DISCOURSE_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["http://discourse.local" "https://discourse.example.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["created" "days_visited" "email" "last_emailed" "posts" "posts_read" "read_time" "seen" "topics_viewed" "trust_level" "username"] }
def asc-completer [] { ["true"] }
def include-subcategories-completer [] { ["true"] }
def period-completer [] { ["all" "daily" "monthly" "quarterly" "weekly" "yearly"] }
def order-completer-1 [] { ["days_visited" "likes_given" "likes_received" "post_count" "posts_read" "topic_count" "topics_entered"] }
def notification-level-completer [] { ["0" "1" "2" "3"] }
def enabled-completer [] { ["false" "true"] }
def status-completer [] { ["archived" "closed" "pinned" "pinned_globally" "visible"] }
def type-completer [] { ["custom" "gravatar" "system" "uploaded"] }
def type-completer-1 [] { ["avatar" "card_background" "composer" "custom_emoji" "profile_background"] }
def upload-type-completer [] { ["avatar" "card_background" "composer" "custom_emoji" "profile_background"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-backups-json get" } } | get name | first)
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

# List backups
#
# GET /admin/backups.json
# operationId: getBackups
export def "admin-backups-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<filename: string, last_modified: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/backups.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create backup
#
# POST /admin/backups.json
# operationId: createBackup
export def "admin-backups-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-uploads: oneof<nothing, bool>
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/backups.json")
  let req_body = {"with_uploads": $with_uploads} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Download backup
#
# GET /admin/backups/{filename}
# operationId: downloadBackup
export def "admin-backups download" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filename: (encode-path-segment $filename)} | format pattern "/admin/backups/{filename}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Send download backup email
#
# PUT /admin/backups/{filename}
# operationId: sendDownloadBackupEmail
export def "admin-backups send-download-email" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({filename: (encode-path-segment $filename)} | format pattern "/admin/backups/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List badges
#
# GET /admin/badges.json
# operationId: adminListBadges
export def "admin-badges-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_badges: record<badge_grouping_ids: list<any>, badge_ids: list<any>, badge_type_ids: list<any>, protected_system_fields: list<any>, triggers: record<none: int, post_action: int, post_revision: int, trust_level_change: int, user_change: int>>, badge_groupings: table<description: string, id: int, name: string, position: int, system: bool>, badge_types: table<id: int, name: string, sort_order: int>, badges: table<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, i18n_name: string, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/badges.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create badge
#
# POST /admin/badges.json
# operationId: createBadge
export def "admin-badges-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  badge_type_id: int # The ID for the badge type. 1 for Gold, 2 for Silver, 3 for Bronze.
  name: string # The name for the new badge.
]: any -> record<badge: record<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: string>, badge_types: table<id: int, name: string, sort_order: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/badges.json")
  let req_body = {"badge_type_id": $badge_type_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete badge
#
# DELETE /admin/badges/{id}.json
# operationId: deleteBadge
export def "admin-badges delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/badges/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update badge
#
# PUT /admin/badges/{id}.json
# operationId: updateBadge
export def "admin-badges update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  badge_type_id: int # The ID for the badge type. 1 for Gold, 2 for Silver, 3 for Bronze.
  name: string # The name for the new badge.
]: any -> record<badge: record<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: string>, badge_types: table<id: int, name: string, sort_order: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/badges/{id}.json"))
  let req_body = {"badge_type_id": $badge_type_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create a group
#
# POST /admin/groups.json
# operationId: createGroup
# --group shape: {automatic_membership_email_domains?: string, bio_raw?: string, default_notification_level?: int, flair_bg_color?: string, flair_icon?: string, flair_upload_id?: int, full_name?: string, muted_category_ids?: list<int>, name: string, owner_usernames?: string, primary_group?: bool, public_admission?: bool, public_exit?: bool, regular_category_ids?: list<int>, tracking_category_ids?: list<int>, usernames?: string, visibility_level?: int, watching_category_ids?: list<int>, ... (1 more fields)}
export def "admin-groups-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group: record # shape: {automatic_membership_email_domains?: string, bio_raw?: string, default_notification_level?: int, flair_bg_color?: string, flair_icon?: string, flair_upload_id?: int, full_name?: string, muted_category_ids?: list<int>, name: string, owner_usernames?: string, primary_group?: bool, public_admission?: bool, public_exit?: bool, regular_category_ids?: list<int>, tracking_category_ids?: list<int>, usernames?: string, visibility_level?: int, watching_category_ids?: list<int>, ... (1 more fields)}
]: any -> record<basic_group: record<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/groups.json")
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a group
#
# DELETE /admin/groups/{id}.json
# operationId: deleteGroup
export def "admin-groups delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/groups/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a list of users
#
# GET /admin/users/list/{flag}.json
# operationId: adminListUsers
export def "admin-users-list list" [
  flag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer
  --asc: string@asc-completer
  --page: int
  --show-emails: oneof<nothing, bool>
]: nothing -> table<active: bool, admin: bool, avatar_template: string, created_at: string, created_at_age: float, days_visited: int, email: string, flag_level: int, id: int, last_emailed_age: float, last_emailed_at: string, last_seen_age: float, last_seen_at: string, manual_locked_trust_level: string, moderator: bool, name: string, post_count: int, posts_read_count: int, secondary_emails: list<any>, staged: bool, time_read: int, title: string, topics_entered: int, trust_level: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "asc" $asc "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "show_emails" $show_emails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({flag: (encode-path-segment $flag)} | format pattern "/admin/users/list/{flag}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete a user
#
# DELETE /admin/users/{id}.json
# operationId: deleteUser
export def "admin-users delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --block-email: oneof<nothing, bool>
  --block-ip: oneof<nothing, bool>
  --block-urls: oneof<nothing, bool>
  --delete-posts: oneof<nothing, bool>
]: any -> record<deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/users/{id}.json"))
  let req_body = {"block_email": $block_email, "block_ip": $block_ip, "block_urls": $block_urls, "delete_posts": $delete_posts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a user by id
#
# GET /admin/users/{id}.json
# operationId: adminGetUser
export def "admin-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, admin: bool, api_key_count: int, approved_by: record<avatar_template: string, id: int, name: string, username: string>, associated_accounts: list<any>, avatar_template: string, badge_count: int, bounce_score: int, can_activate: bool, can_be_anonymized: bool, can_be_deleted: bool, can_be_merged: bool, can_deactivate: bool, can_delete_all_posts: bool, can_delete_sso_record: bool, can_disable_second_factor: bool, can_grant_admin: bool, can_grant_moderation: bool, can_impersonate: bool, can_revoke_admin: bool, can_revoke_moderation: bool, can_send_activation_email: bool, can_view_action_logs: bool, created_at: string, created_at_age: float, days_visited: int, external_ids: record, flag_level: int, flags_given_count: int, flags_received_count: int, full_suspend_reason: string, groups: table<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_see_members: bool, default_notification_level: int, display_name: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>, id: int, ip_address: string, last_emailed_age: float, last_emailed_at: string, last_seen_age: float, last_seen_at: string, like_count: int, like_given_count: int, manual_locked_trust_level: string, moderator: bool, name: string, next_penalty: string, penalty_counts: record<silenced: int, suspended: int>, post_count: int, post_edits_count: int, posts_read_count: int, primary_group_id: string, private_topics_count: int, registration_ip_address: string, reset_bounce_score_after: string, silence_reason: string, silenced_by: string, single_sign_on_record: string, staged: bool, suspended_by: string, time_read: int, title: string, tl3_requirements: record<days_visited: int, max_flagged_by_users: int, max_flagged_posts: int, min_days_visited: int, min_likes_given: int, min_likes_received: int, min_likes_received_days: int, min_likes_received_users: int, min_posts_read: int, min_posts_read_all_time: int, min_topics_replied_to: int, min_topics_viewed: int, min_topics_viewed_all_time: int, num_flagged_by_users: int, num_flagged_posts: int, num_likes_given: int, num_likes_received: int, num_likes_received_days: int, num_likes_received_users: int, num_topics_replied_to: int, on_grace_period: bool, penalty_counts: record<silenced: int, suspended: int, total: int>, posts_read: int, posts_read_all_time: int, requirements_lost: bool, requirements_met: bool, time_period: int, topics_viewed: int, topics_viewed_all_time: int, trust_level_locked: bool>, topic_count: int, topics_entered: int, trust_level: int, username: string, warnings_received_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/users/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Anonymize a user
#
# PUT /admin/users/{id}/anonymize.json
# operationId: anonymizeUser
export def "admin-users-anonymize-json update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/users/{id}/anonymize.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Log a user out
#
# POST /admin/users/{id}/log_out.json
# operationId: logOutUser
export def "admin-users-log-out-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/users/{id}/log_out.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Silence a user
#
# PUT /admin/users/{id}/silence.json
# operationId: silenceUser
export def "admin-users-silence-json update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # Will send an email with this message when present
  --post-action: string
  --reason: string
  --silenced-till: string
]: any -> record<silence: record<silence_reason: string, silenced: bool, silenced_at: string, silenced_by: record<avatar_template: string, id: int, name: string, username: string>, silenced_till: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/users/{id}/silence.json"))
  let req_body = {"message": $message, "post_action": $post_action, "reason": $reason, "silenced_till": $silenced_till} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Suspend a user
#
# PUT /admin/users/{id}/suspend.json
# operationId: suspendUser
export def "admin-users-suspend-json update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # Will send an email with this message when present
  --post-action: string
  reason: string
  suspend_until: string
]: any -> record<suspension: record<full_suspend_reason: string, suspend_reason: string, suspended_at: string, suspended_by: record<avatar_template: string, id: int, name: string, username: string>, suspended_till: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/users/{id}/suspend.json"))
  let req_body = {"message": $message, "post_action": $post_action, "reason": $reason, "suspend_until": $suspend_until} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Show category
#
# GET /c/{id}/show.json
# operationId: getCategory
export def "c-show-json get-category" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/c/{id}/show.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List topics
#
# GET /c/{slug}/{id}.json
# operationId: listCategoryTopics
export def "c list-category-topics" [
  slug: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, per_page: int, top_tags: list<any>, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({slug: (encode-path-segment $slug), id: (encode-path-segment $id)} | format pattern "/c/{slug}/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a list of categories
#
# GET /categories.json
# operationId: listCategories
export def "categories-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-subcategories: oneof<nothing, bool>
]: nothing -> record<category_list: record<can_create_category: bool, can_create_topic: bool, categories: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_subcategories" $include_subcategories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a category
#
# POST /categories.json
# operationId: createCategory
# --permissions shape: {everyone?: int, staff?: int}
export def "categories-json create-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-badges: oneof<nothing, bool>
  --color: string
  --form-template-ids: list
  name: string
  --parent-category-id: int
  --permissions: record # shape: {everyone?: int, staff?: int}
  --search-priority: int
  --slug: string
  --text-color: string
  --topic-featured-links-allowed: oneof<nothing, bool>
]: any -> record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories.json")
  let req_body = {"allow_badges": $allow_badges, "color": $color, "form_template_ids": $form_template_ids, "name": $name, "parent_category_id": $parent_category_id, "permissions": $permissions, "search_priority": $search_priority, "slug": $slug, "text_color": $text_color, "topic_featured_links_allowed": $topic_featured_links_allowed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a category
#
# PUT /categories/{id}.json
# operationId: updateCategory
# --permissions shape: {everyone?: int, staff?: int}
export def "categories update-category" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-badges: oneof<nothing, bool>
  --color: string
  --form-template-ids: list
  name: string
  --parent-category-id: int
  --permissions: record # shape: {everyone?: int, staff?: int}
  --search-priority: int
  --slug: string
  --text-color: string
  --topic-featured-links-allowed: oneof<nothing, bool>
]: any -> record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: string, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>, success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}.json"))
  let req_body = {"allow_badges": $allow_badges, "color": $color, "form_template_ids": $form_template_ids, "name": $name, "parent_category_id": $parent_category_id, "permissions": $permissions, "search_priority": $search_priority, "slug": $slug, "text_color": $text_color, "topic_featured_links_allowed": $topic_featured_links_allowed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a public list of users
#
# GET /directory_items.json
# operationId: listUsersPublic
export def "directory-items-json list-users-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer
  --order: string@order-completer-1
  --asc: string@asc-completer
  --page: int
]: nothing -> record<directory_items: table<days_visited: int, id: int, likes_given: int, likes_received: int, post_count: int, posts_read: int, topic_count: int, topics_entered: int, user: record>, meta: record<last_updated_at: string, load_more_directory_items: string, total_rows_directory_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "asc" $asc "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/directory_items.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List groups
#
# GET /groups.json
# operationId: listGroups
export def "groups-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<extras: record<type_filters: list<any>>, groups: table<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, display_name: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, is_group_owner: bool, is_group_user: bool, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>, load_more_groups: string, total_rows_groups: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a group
#
# GET /groups/{id}.json
# operationId: getGroup
export def "groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<extras: record<visible_group_names: list<any>>, group: record<allow_membership_requests: bool, allow_unknown_sender_topic_replies: bool, associated_group_ids: list<any>, automatic: bool, automatic_membership_email_domains: string, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, email_from_alias: string, email_password: string, email_username: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, imap_enabled: bool, imap_last_error: string, imap_mailbox_name: string, imap_mailboxes: list<any>, imap_new_emails: string, imap_old_emails: string, imap_port: string, imap_server: string, imap_ssl: string, imap_updated_at: string, imap_updated_by: record, incoming_email: string, is_group_owner_display: bool, is_group_user: bool, members_visibility_level: int, membership_request_template: string, mentionable: bool, mentionable_level: int, message_count: int, messageable: bool, messageable_level: int, muted_category_ids: list<any>, muted_tags: list<any>, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, regular_category_ids: list<any>, regular_tags: list<any>, smtp_enabled: bool, smtp_port: string, smtp_server: string, smtp_ssl: string, smtp_updated_at: string, smtp_updated_by: record, title: string, tracking_category_ids: list<any>, tracking_tags: list<any>, user_count: int, visibility_level: int, watching_category_ids: list<any>, watching_first_post_category_ids: list<any>, watching_first_post_tags: list<any>, watching_tags: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a group
#
# PUT /groups/{id}.json
# operationId: updateGroup
# --group shape: {automatic_membership_email_domains?: string, bio_raw?: string, default_notification_level?: int, flair_bg_color?: string, flair_icon?: string, flair_upload_id?: int, full_name?: string, muted_category_ids?: list<int>, name: string, owner_usernames?: string, primary_group?: bool, public_admission?: bool, public_exit?: bool, regular_category_ids?: list<int>, tracking_category_ids?: list<int>, usernames?: string, visibility_level?: int, watching_category_ids?: list<int>, ... (1 more fields)}
export def "groups update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group: record # shape: {automatic_membership_email_domains?: string, bio_raw?: string, default_notification_level?: int, flair_bg_color?: string, flair_icon?: string, flair_upload_id?: int, full_name?: string, muted_category_ids?: list<int>, name: string, owner_usernames?: string, primary_group?: bool, public_admission?: bool, public_exit?: bool, regular_category_ids?: list<int>, tracking_category_ids?: list<int>, usernames?: string, visibility_level?: int, watching_category_ids?: list<int>, ... (1 more fields)}
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}.json"))
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove group members
#
# DELETE /groups/{id}/members.json
# operationId: removeGroupMembers
export def "groups-members-json delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usernames: string # comma separated list
]: any -> record<skipped_usernames: list<any>, success: string, usernames: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/members.json"))
  let req_body = {"usernames": $usernames} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List group members
#
# GET /groups/{id}/members.json
# operationId: listGroupMembers
export def "groups-members-json list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<members: table<added_at: string, avatar_template: string, id: int, last_posted_at: string, last_seen_at: string, name: string, timezone: string, title: string, username: string>, meta: record<limit: int, offset: int, total: int>, owners: table<added_at: string, avatar_template: string, id: int, last_posted_at: string, last_seen_at: string, name: string, timezone: string, title: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/members.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add group members
#
# PUT /groups/{id}/members.json
# operationId: addGroupMembers
export def "groups-members-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usernames: string # comma separated list
]: any -> record<emails: list<any>, success: string, usernames: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/members.json"))
  let req_body = {"usernames": $usernames} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create an invite
#
# POST /invites.json
# operationId: createInvite
export def "invites-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --custom-message: string # optional, for email invites
  --email: string # required for email invites only
  --expires-at: string # optional, if not supplied, the invite_expiry_days site setting is used
  --group-id: int # optional, either this or `group_names`
  --group-names: string # optional, either this or `group_id`
  --max-redemptions-allowed: int # optional, for link invites (default: 1)
  --skip-email: oneof<nothing, bool> # default: false
  --topic-id: int
]: any -> record<created_at: string, custom_message: string, email: string, emailed: bool, expired: bool, expires_at: string, groups: list<any>, id: int, link: string, topics: list<any>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invites.json")
  let req_body = {"custom_message": $custom_message, "email": $email, "expires_at": $expires_at, "group_id": $group_id, "group_names": $group_names, "max_redemptions_allowed": $max_redemptions_allowed, "skip_email": $skip_email, "topic_id": $topic_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get the latest topics
#
# GET /latest.json
# operationId: listLatestTopics
export def "latest-json list-topics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # Enum: `default`, `created`, `activity`, `views`, `posts`, `category`, `likes`, `op_likes`, `posters`
  --ascending: string # Defaults to `desc`, add `ascending=true` to sort asc
  --api-key: string
  --api-username: string
]: nothing -> record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "ascending" $ascending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/latest.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the notifications that belong to the current user
#
# GET /notifications.json
# operationId: getNotifications
export def "notifications-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<load_more_notifications: string, notifications: table<created_at: string, data: record, id: int, notification_type: int, post_number: string, read: bool, slug: string, topic_id: int, user_id: int>, seen_notification_id: int, total_rows_notifications: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Mark notifications as read
#
# PUT /notifications/mark-read.json
# operationId: markNotificationsAsRead
export def "notifications-mark-read-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # (optional) Leave off to mark all notifications as read
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/mark-read.json")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Like a post and other actions
#
# POST /post_actions.json
# operationId: performPostAction
export def "post-actions-json create-perform" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --flag-topic: oneof<nothing, bool>
  id: int
  post_action_type_id: int
]: any -> record<actions_summary: table<acted: bool, can_undo: bool, count: int, id: int>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, notice: record, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/post_actions.json")
  let req_body = {"flag_topic": $flag_topic, "id": $id, "post_action_type_id": $post_action_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List latest posts across topics
#
# GET /posts.json
# operationId: listPosts
export def "posts-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Load posts with an id lower than this value. Useful for pagination.
  --api-key: string
  --api-username: string
]: nothing -> record<latest_posts: table<actions_summary: list, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, category_id: int, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_html_title: string, topic_id: int, topic_slug: string, topic_title: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a new topic, a new post, or a private message
#
# POST /posts.json
# operationId: createTopicPostPM
@deprecated --flag target-usernames
export def "posts-json create-topic-pm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archetype: string # Required for new private message.
  --category: int # Optional if creating a new topic, and ignored if creating a new post.
  --created-at: string
  --embed-url: string # Provide a URL from a remote system to associate a forum topic with that URL, typically for using Discourse as a comments system for an external blog.
  --external-id: string # Provide an external_id from a remote system to associate a forum topic with that id.
  --body-raw: string
  --target-recipients: string # Required for private message, comma separated.
  --target-usernames: string # Deprecated. Use target_recipients instead. (DEPRECATED)
  --title: string # Required if creating a new topic or new private message.
  --topic-id: int # Required if creating a new post.
]: any -> record<actions_summary: table<can_act: bool, id: int>, admin: bool, avatar_template: string, bookmarked: bool, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, draft_sequence: int, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, mentioned_users: list<any>, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/posts.json")
  let req_body = {"archetype": $archetype, "category": $category, "created_at": $created_at, "embed_url": $embed_url, "external_id": $external_id, "raw": $body_raw, "target_recipients": $target_recipients, "target_usernames": $target_usernames, "title": $title, "topic_id": $topic_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# delete a single post
#
# DELETE /posts/{id}.json
# operationId: deletePost
export def "posts delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-destroy: oneof<nothing, bool> # The `SiteSetting.can_permanently_delete` needs to be enabled first before this param can be used. Also this endpoint needs to be called first without `force_destroy` and then followed up with a second call 5 minutes later with `force_destroy` to permanently delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/posts/{id}.json"))
  let req_body = {"force_destroy": $force_destroy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve a single post
#
# GET /posts/{id}.json
# operationId: getPost
export def "posts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
]: nothing -> record<actions_summary: table<can_act: bool, id: int>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/posts/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a single post
#
# PUT /posts/{id}.json
# operationId: updatePost
# --post shape: {edit_reason?: string, raw: string}
export def "posts update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --post: record # shape: {edit_reason?: string, raw: string}
]: any -> record<post: record<actions_summary: list<record>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, draft_sequence: int, edit_reason: string, flair_bg_color: string, flair_color: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/posts/{id}.json"))
  let req_body = {"post": $post} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lock a post from being edited
#
# PUT /posts/{id}/locked.json
# operationId: lockPost
export def "posts-locked-json lock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  locked: string
]: any -> record<locked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/posts/{id}/locked.json"))
  let req_body = {"locked": $locked} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List replies to a post
#
# GET /posts/{id}/replies.json
# operationId: postReplies
export def "posts-replies-json create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<actions_summary: list<record>, admin: bool, avatar_template: string, bookmarked: bool, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: int, reply_to_user: record<avatar_template: string, name: string, username: string>, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/posts/{id}/replies.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search for a term
#
# GET /search.json
# operationId: search
export def "search-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The query string needs to be url encoded and is made up of the following options: - Search term. This is just a string. Usually it would be the first item in the query. - `@`: Use the `@` followed by the username to specify posts by this user. - `#`: Use the `#` followed by the category slug to search within this category. - `tags:`: `api,solved` or for posts that have all the specified tags `api+solved`. - `before:`: `yyyy-mm-dd` - `after:`: `yyyy-mm-dd` - `order:`: `latest`, `likes`, `views`, `latest_topic` - `assigned:`: username (without `@`) - `in:`: `title`, `likes`, `personal`, `messages`, `seen`, `unseen`, `posted`, `created`, `watching`, `tracking`, `bookmarks`, `assigned`, `unassigned`, `first`, `pinned`, `wiki` - `with:`: `images` - `status:`: `open`, `closed`, `public`, `archived`, `noreplies`, `single_user`, `solved`, `unsolved` - `group:`: group_name or group_id - `group_messages:`: group_name or group_id - `min_posts:`: 1 - `max_posts:`: 10 - `min_views:`: 1 - `max_views:`: 10 If you are using cURL you can use the `-G` and the `--data-urlencode` flags to encode the query: ``` curl -i -sS -X GET -G "http://localhost:4200/search.json" \ --data-urlencode 'q=wordpress @scossar #fun after:2020-01-01' ``` (e.g. api @blake #support tags:api after:2021-06-04 in:unseen in:open order:latest_topic)
  --page: int # e.g. 1
]: nothing -> record<categories: list<any>, grouped_search_result: record<can_create_topic: bool, category_ids: list<any>, error: string, group_ids: list<any>, more_categories: string, more_full_page_results: string, more_posts: string, more_users: string, post_ids: list<any>, search_log_id: int, tag_ids: list<any>, term: string, user_ids: list<any>>, groups: list<any>, posts: list<any>, tags: list<any>, users: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Send password reset email
#
# POST /session/forgot_password.json
# operationId: sendPasswordResetEmail
export def "session-forgot-password-json send-reset-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  login: string
]: any -> record<success: string, user_found: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/session/forgot_password.json")
  let req_body = {"login": $login} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get site info
#
# GET /site.json
# operationId: getSite
export def "site-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<anonymous_top_menu_items: list<any>, archetypes: table<id: string, name: string, options: list>, auth_providers: list<any>, can_associate_groups: bool, can_create_tag: bool, can_tag_pms: bool, can_tag_topics: bool, categories: table<allow_global_tags: bool, allowed_tag_groups: list, allowed_tags: list, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, form_template_ids: list, has_children: bool, id: int, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, parent_category_id: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>, censored_regexp: list<record>, custom_emoji_translation: record, default_archetype: string, default_dark_color_scheme: record, displayed_about_plugin_stat_groups: list<any>, filters: list<any>, groups: table<flair_bg_color: string, flair_color: string, flair_url: string, id: int, name: string>, hashtag_configurations: record, hashtag_icons: list<any>, markdown_additional_options: record, notification_types: record<assigned: int, bookmark_reminder: int, chat_group_mention: int, chat_invitation: int, chat_mention: int, chat_message: int, chat_quoted: int, circles_activity: int, code_review_commit_approved: int, custom: int, edited: int, event_invitation: int, event_reminder: int, following: int, following_created_topic: int, following_replied: int, granted_badge: int, group_mentioned: int, group_message_summary: int, invited_to_private_message: int, invited_to_topic: int, invitee_accepted: int, liked: int, liked_consolidated: int, linked: int, membership_request_accepted: int, membership_request_consolidated: int, mentioned: int, moved_post: int, new_features: int, post_approved: int, posted: int, private_message: int, question_answer_user_commented: int, quoted: int, reaction: int, replied: int, topic_reminder: int, votes_released: int, watching_category_or_tag: int, watching_first_post: int>, periods: list<any>, post_action_types: table<description: string, id: int, is_custom_flag: bool, is_flag: bool, name: string, name_key: string, short_description: string>, post_types: record<moderator_action: int, regular: int, small_action: int, whisper: int>, show_welcome_topic_banner: bool, tags_filter_regexp: string, top_menu_items: list<any>, top_tags: list<any>, topic_featured_link_allowed_category_ids: list<any>, topic_flag_types: table<description: string, id: int, is_custom_flag: bool, is_flag: bool, name: string, name_key: string, short_description: string>, trust_levels: record<basic: int, leader: int, member: int, newuser: int, regular: int>, uncategorized_category_id: int, user_color_schemes: table<id: int, is_dark: bool, name: string>, user_field_max_length: int, user_fields: list<any>, user_themes: table<color_scheme_id: int, default: bool, name: string, theme_id: int>, watched_words_link: string, watched_words_replace: string, whispers_allowed_groups_names: list<any>, wizard_required: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/site.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a topic
#
# PUT /t/-/{id}.json
# operationId: updateTopic
# --topic shape: {category_id?: int, title?: string}
export def "t update-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --topic: record # shape: {category_id?: int, title?: string}
]: any -> record<basic_topic: record<fancy_title: string, id: int, posts_count: int, slug: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/-/{id}.json"))
  let req_body = {"topic": $topic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get topic by external_id
#
# GET /t/external_id/{external_id}.json
# operationId: getTopicByExternalId
export def "t-external-id get-topic" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({external_id: (encode-path-segment $external_id)} | format pattern "/t/external_id/{external_id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove a topic
#
# DELETE /t/{id}.json
# operationId: removeTopic
export def "t delete-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single topic
#
# GET /t/{id}.json
# operationId: getTopic
export def "t get-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
]: nothing -> record<actions_summary: table<can_act: bool, count: int, hidden: bool, id: int>, archetype: string, archived: bool, bookmarked: bool, bookmarks: list<any>, category_id: int, chunk_size: int, closed: bool, created_at: string, current_post_number: int, deleted_at: string, deleted_by: string, details: record<can_archive_topic: bool, can_close_topic: bool, can_convert_topic: bool, can_create_post: bool, can_delete: bool, can_edit: bool, can_edit_staff_notes: bool, can_flag_topic: bool, can_invite_to: bool, can_invite_via_email: bool, can_moderate_category: bool, can_move_posts: bool, can_pin_unpin_topic: bool, can_remove_allowed_users: bool, can_remove_self_id: int, can_reply_as_new_topic: bool, can_review_topic: bool, can_split_merge_topic: bool, can_toggle_topic_visibility: bool, created_by: record<avatar_template: string, id: int, name: string, username: string>, last_poster: record<avatar_template: string, id: int, name: string, username: string>, notification_level: int, participants: list<record>>, draft: string, draft_key: string, draft_sequence: int, fancy_title: string, featured_link: string, has_deleted: bool, has_summary: bool, highest_post_number: int, id: int, image_url: string, last_posted_at: string, like_count: int, message_bus_last_id: int, participant_count: int, pinned: bool, pinned_at: string, pinned_globally: bool, pinned_until: string, post_stream: record<posts: list<record>, stream: list<any>>, posts_count: int, reply_count: int, show_read_indicator: bool, slow_mode_enabled_until: string, slow_mode_seconds: int, slug: string, suggested_topics: table<archetype: string, archived: bool, bookmarked: string, bumped: bool, bumped_at: string, category_id: int, closed: bool, created_at: string, excerpt: string, fancy_title: string, featured_link: string, highest_post_number: int, id: int, image_url: string, last_posted_at: string, like_count: int, liked: string, pinned: bool, posters: list, posts_count: int, reply_count: int, slug: string, tags: list, tags_descriptions: record, title: string, unpinned: string, unseen: bool, views: int, visible: bool>, tags: list<any>, tags_descriptions: record, thumbnails: string, timeline_lookup: list<any>, title: string, topic_timer: string, unpinned: string, user_id: int, views: int, visible: bool, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Bookmark topic
#
# PUT /t/{id}/bookmark.json
# operationId: bookmarkTopic
export def "t-bookmark-json update-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}/bookmark.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update topic timestamp
#
# PUT /t/{id}/change-timestamp.json
# operationId: updateTopicTimestamp
export def "t-change-timestamp-json update-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  timestamp: string
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}/change-timestamp.json"))
  let req_body = {"timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Invite to topic
#
# POST /t/{id}/invite.json
# operationId: inviteToTopic
export def "t-invite-json create-to-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --email: string
  --user: string
]: any -> record<user: record<avatar_template: string, id: int, name: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}/invite.json"))
  let req_body = {"email": $email, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Set notification level
#
# POST /t/{id}/notifications.json
# operationId: setNotificationLevel
export def "t-notifications-json update-level" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  notification_level: string@notification-level-completer
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}/notifications.json"))
  let req_body = {"notification_level": $notification_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get specific posts from a topic
#
# GET /t/{id}/posts.json
# operationId: getSpecificPostsFromTopic
export def "t-posts-json get-specific-from-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  post_ids: int
]: any -> record<id: int, post_stream: record<posts: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}/posts.json"))
  let req_body = {"post_ids[]": $post_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update the status of a topic
#
# PUT /t/{id}/status.json
# operationId: updateTopicStatus
export def "t-status-json update-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  enabled: string@enabled-completer
  status: string@status-completer
  --until: string # Only required for `pinned` and `pinned_globally`
]: any -> record<success: string, topic_status_update: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}/status.json"))
  let req_body = {"enabled": $enabled, "status": $status, "until": $until} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create topic timer
#
# POST /t/{id}/timer.json
# operationId: createTopicTimer
export def "t-timer-json create-topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --based-on-last-post: oneof<nothing, bool>
  --category-id: int
  --status-type: string
  --time: string
]: any -> record<based_on_last_post: bool, category_id: string, closed: bool, duration: string, execute_at: string, success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/t/{id}/timer.json"))
  let req_body = {"based_on_last_post": $based_on_last_post, "category_id": $category_id, "status_type": $status_type, "time": $time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a specific tag
#
# GET /tag/{name}.json
# operationId: getTag
export def "tag get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, tags: list<record>, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/tag/{name}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a list of tag groups
#
# GET /tag_groups.json
# operationId: listTagGroups
export def "tag-groups-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tag_groups: table<id: int, name: string, one_per_topic: bool, parent_tag_name: list, permissions: record, tag_names: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tag_groups.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a tag group
#
# POST /tag_groups.json
# operationId: createTagGroup
export def "tag-groups-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record, tag_names: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tag_groups.json")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a single tag group
#
# GET /tag_groups/{id}.json
# operationId: getTagGroup
export def "tag-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record<everyone: int>, tag_names: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tag_groups/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update tag group
#
# PUT /tag_groups/{id}.json
# operationId: updateTagGroup
export def "tag-groups update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> record<success: string, tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record<everyone: int>, tag_names: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tag_groups/{id}.json"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a list of tags
#
# GET /tags.json
# operationId: listTags
export def "tags-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<extras: record<categories: list<any>>, tags: table<count: int, id: string, pm_count: int, target_tag: string, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the top topics filtered by period
#
# GET /top.json
# operationId: listTopTopics
export def "top-json list-topics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string # Enum: `all`, `yearly`, `quarterly`, `monthly`, `weekly`, `daily`
  --api-key: string
  --api-username: string
]: nothing -> record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, for_period: string, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/top.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a list of private messages sent for a user
#
# GET /topics/private-messages-sent/{username}.json
# operationId: getUserSentPrivateMessages
export def "topics-private-messages-sent get-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/topics/private-messages-sent/{username}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a list of private messages for a user
#
# GET /topics/private-messages/{username}.json
# operationId: listUserPrivateMessages
export def "topics-private-messages list-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/topics/private-messages/{username}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a user by external_id
#
# GET /u/by-external/{external_id}.json
# operationId: getUserExternalId
export def "u-by-external get-user" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
]: nothing -> record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<1: string, 2: string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({external_id: (encode-path-segment $external_id)} | format pattern "/u/by-external/{external_id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a user by identity provider external ID
#
# GET /u/by-external/{provider}/{external_id}.json
# operationId: getUserIdentiyProviderExternalId
export def "u-by-external get-user-identiy" [
  provider: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
]: nothing -> record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<1: string, 2: string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider: (encode-path-segment $provider), external_id: (encode-path-segment $external_id)} | format pattern "/u/by-external/{provider}/{external_id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single user by username
#
# GET /u/{username}.json
# operationId: getUser
export def "u get-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
]: nothing -> record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<1: string, 2: string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/u/{username}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a user
#
# PUT /u/{username}.json
# operationId: updateUser
export def "u update-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --email: string
  --external-ids: record
  --name: string
  --password: string
]: any -> record<success: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/u/{username}.json"))
  let req_body = {"email": $email, "external_ids": $external_ids, "name": $name, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get email addresses belonging to a user
#
# GET /u/{username}/emails.json
# operationId: getUserEmails
export def "u-emails-json get-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<associated_accounts: list<any>, email: string, secondary_emails: list<any>, unconfirmed_emails: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/u/{username}/emails.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update avatar
#
# PUT /u/{username}/preferences/avatar/pick.json
# operationId: updateAvatar
export def "u-preferences-avatar-pick-json update" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer
  upload_id: int
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/u/{username}/preferences/avatar/pick.json"))
  let req_body = {"type": $type, "upload_id": $upload_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update email
#
# PUT /u/{username}/preferences/email.json
# operationId: updateEmail
export def "u-preferences-email-json update" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/u/{username}/preferences/email.json"))
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update username
#
# PUT /u/{username}/preferences/username.json
# operationId: updateUsername
export def "u-preferences-username-json update" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/u/{username}/preferences/username.json"))
  let req_body = {"new_username": $new_username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates an upload
#
# POST /uploads.json
# operationId: createUpload
export def "uploads-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: any
  --synchronous: oneof<nothing, bool> # Use this flag to return an id and url
  type: string@type-completer-1
  --user-id: int # required if uploading an avatar
]: any -> record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads.json")
  let req_body = {"file": $file, "synchronous": $synchronous, "type": $type, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Abort multipart upload
#
# POST /uploads/abort-multipart.json
# operationId: abortMultipart
export def "uploads-abort-multipart-json abort" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  external_upload_identifier: string # The identifier of the multipart upload in the external storage provider. This is the multipart upload_id in AWS S3.
]: any -> record<success: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/abort-multipart.json")
  let req_body = {"external_upload_identifier": $external_upload_identifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Generates batches of presigned URLs for multipart parts
#
# POST /uploads/batch-presign-multipart-parts.json
# operationId: batchPresignMultipartParts
export def "uploads-batch-presign-multipart-parts-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  part_numbers: list # The part numbers to generate the presigned URLs for, must be between 1 and 10000.
  unique_identifier: string # The unique identifier returned in the original /create-multipart request.
]: any -> record<presigned_urls: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/batch-presign-multipart-parts.json")
  let req_body = {"part_numbers": $part_numbers, "unique_identifier": $unique_identifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Completes a direct external upload
#
# POST /uploads/complete-external-upload.json
# operationId: completeExternalUpload
export def "uploads-complete-external-upload-json complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-private-message: string # Optionally set this to true if the upload is for a private message.
  --for-site-setting: string # Optionally set this to true if the upload is for a site setting.
  --pasted: string # Optionally set this to true if the upload was pasted into the upload area. This will convert PNG files to JPEG.
  unique_identifier: string # The unique identifier returned in the original /generate-presigned-put request.
]: any -> record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/complete-external-upload.json")
  let req_body = {"for_private_message": $for_private_message, "for_site_setting": $for_site_setting, "pasted": $pasted, "unique_identifier": $unique_identifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Complete multipart upload
#
# POST /uploads/complete-multipart.json
# operationId: completeMultipart
export def "uploads-complete-multipart-json complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parts: list # All of the part numbers and their corresponding ETags that have been uploaded must be provided.
  unique_identifier: string # The unique identifier returned in the original /create-multipart request.
]: any -> record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/complete-multipart.json")
  let req_body = {"parts": $parts, "unique_identifier": $unique_identifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a multipart external upload
#
# POST /uploads/create-multipart.json
# operationId: createMultipartUpload
# --metadata shape: {sha1-checksum?: string}
export def "uploads-create-multipart-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_name: string
  file_size: int # File size should be represented in bytes.
  --metadata: record # shape: {sha1-checksum?: string}
  upload_type: string@upload-type-completer
]: any -> record<external_upload_identifier: string, key: string, unique_identifier: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/create-multipart.json")
  let req_body = {"file_name": $file_name, "file_size": $file_size, "metadata": $metadata, "upload_type": $upload_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Initiates a direct external upload
#
# POST /uploads/generate-presigned-put.json
# operationId: generatePresignedPut
# --metadata shape: {sha1-checksum?: string}
export def "uploads-generate-presigned-put-json generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_name: string
  file_size: int # File size should be represented in bytes.
  --metadata: record # shape: {sha1-checksum?: string}
  type: string@type-completer-1
]: any -> record<key: string, unique_identifier: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads/generate-presigned-put.json")
  let req_body = {"file_name": $file_name, "file_size": $file_size, "metadata": $metadata, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List badges for a user
#
# GET /user-badges/{username}.json
# operationId: listUserBadges
export def "user-badges list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<badge_types: table<id: int, name: string, sort_order: int>, badges: table<allow_title: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, manually_grantable: bool, multiple_grant: bool, name: string, slug: string, system: bool>, granted_bies: table<admin: bool, avatar_template: string, flair_name: string, id: int, moderator: bool, name: string, trust_level: int, username: string>, user_badges: table<badge_id: int, can_favorite: bool, granted_at: string, granted_by_id: int, grouping_position: int, id: int, is_favorite: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/user-badges/{username}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a list of user actions
#
# GET /user_actions.json
# operationId: listUserActions
export def "user-actions-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --username: string
  --filter: string
]: nothing -> record<user_actions: table<acting_avatar_template: string, acting_name: string, acting_user_id: int, acting_username: string, action_code: string, action_type: int, archived: bool, avatar_template: string, category_id: int, closed: bool, created_at: string, deleted: bool, excerpt: string, hidden: string, name: string, post_id: string, post_number: int, post_type: string, slug: string, target_name: string, target_user_id: int, target_username: string, title: string, topic_id: int, user_id: int, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_actions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Refresh gravatar
#
# POST /user_avatar/{username}/refresh_gravatar.json
# operationId: refreshGravatar
export def "user-avatar-refresh-gravatar-json refresh" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gravatar_avatar_template: string, gravatar_upload_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/user_avatar/{username}/refresh_gravatar.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a user
#
# POST /users.json
# operationId: createUser
export def "users-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --api-username: string
  --active: oneof<nothing, bool> # This param requires an api key in the request header or it will be ignored
  --approved: oneof<nothing, bool>
  email: string
  --external-ids: record
  name: string
  password: string
  --user-fields-1: oneof<nothing, bool>
  username: string
]: any -> record<active: bool, message: string, success: bool, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users.json")
  let req_body = {"active": $active, "approved": $approved, "email": $email, "external_ids": $external_ids, "name": $name, "password": $password, "user_fields[1]": $user_fields_1, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Api-Key": $api_key, "Api-Username": $api_username} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Change password
#
# PUT /users/password-reset/{token}.json
# operationId: changePassword
export def "users-password-reset update-change" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/users/password-reset/{token_arg}.json"))
  let req_body = {"password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
