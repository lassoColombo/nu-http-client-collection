# Auto-generated client for uebermaps API endpoints v2.0
# Source: https://api.apis.guru/v2/specs/uebermaps.com/2.0/swagger.json
# Auth: --token flag or $env.UEBERMAPS_API_ENDPOINTS_TOKEN

const BASE_URL = "https://uebermaps.com/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o UEBERMAPS_API_ENDPOINTS_TOKEN | default "" }
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

def base-url-completer [] { ["https://uebermaps.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def visibility-completer [] { ["link" "private" "public"] }
def group-completer [] { ["admin" "editor"] }
def order-completer [] { ["created_at_asc" "created_at_desc" "title_asc" "title_desc" "updated_at_asc" "updated_at_desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account update" } } | get name | first)
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

# Update account
#
# PATCH /account
export def "account update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. The comedian
  --header: string # e.g. <BASE_64_ENCODED_STRING>
  --language: string # e.g. en
  --location: string # e.g. Little Rock, Arkansas
  --name: string # e.g. Bill Hicks
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --screen-name: string # e.g. billhicks
  --time-zone: string # e.g. Pacific Time (US & Canada)
  --url: string # e.g. http://www.billhicks.com
]: any -> record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let req_body = {"about": $about, "header": $header, "language": $language, "location": $location, "name": $name, "picture": $picture, "screen_name": $screen_name, "time_zone": $time_zone, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete attachment
#
# DELETE /attachments/{id}
export def "attachments delete" [
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
]: nothing -> record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/attachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Sign in user
#
# POST /authentication
export def "authentication create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # e.g. a@b.com
  --password: string # e.g. ••••••••
]: any -> record<auth_token: string, language: string, time_zone: string, about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication")
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List your collaborator invitations
#
# GET /collaborator_invitations
export def "collaborator-invitations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborator_invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Invite user to collaborate on map
#
# POST /collaborator_invitations
export def "collaborator-invitations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: string # e.g. a@b.com, c@d.com, e@f.com
  --is-admin: oneof<nothing, bool> # e.g. true
  --map-id: int # e.g. 34925783
  --user-ids: string # e.g. 5839459, 389423, 89494, 686950
]: any -> record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborator_invitations")
  let req_body = {"emails": $emails, "is_admin": $is_admin, "map_id": $map_id, "user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete collaborator invitation
#
# DELETE /collaborator_invitations/{id}
export def "collaborator-invitations delete" [
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
]: nothing -> record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/collaborator_invitations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show collaborator invitation
#
# GET /collaborator_invitations/{id}
export def "collaborator-invitations get" [
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
]: nothing -> record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/collaborator_invitations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Accept collaborator invitation.
#
# PATCH /collaborator_invitations/{id}
export def "collaborator-invitations update" [
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
]: nothing -> record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/collaborator_invitations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete comment
#
# DELETE /comments/{id}
export def "comments delete" [
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
]: nothing -> record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/comments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update comment
#
# PATCH /comments/{id}
export def "comments update" [
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
  --body: string # e.g. Nice photo
]: any -> record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/comments/{id}"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List your own events
#
# GET /events
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeframe-start: string # Begin of time range of event (ISO 8601 date format).
  --timeframe-end: string # End of time range of event (ISO 8601 date format).
  --bounds: string # To refine your event index request to contain only events within a geographical box pass the followng bounds parameters. F. e. to get events within 'Hamburg, St. Pauli': bounds[sw_lat]=53.54831449741324 bounds[sw_lon]=9.943227767944336 bounds[ne_lat]=53.5571103674878 bounds[ne_lon]=9.9776029586792
]: nothing -> table<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe_start" $timeframe_start "scalar") (serialize-qp "timeframe_end" $timeframe_end "scalar") (serialize-qp "bounds" $bounds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete event
#
# DELETE /events/{id}
export def "events delete" [
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
]: nothing -> record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get event
#
# GET /events/{id}
export def "events get" [
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
]: nothing -> record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update event
#
# PATCH /events/{id}
export def "events update" [
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
  --description: string # e.g. Very special event
  --ends-at: string # format: date-time
  --lat: float # e.g. 53.293493
  --lon: float # e.g. 12.394328
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --starts-at: string # format: date-time
  --time-zone: string # e.g. Berlin
  --title: string # e.g. 20th anniversary event
  --user-id: int # e.g. 703943
]: any -> record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}"))
  let req_body = {"description": $description, "ends_at": $ends_at, "lat": $lat, "lon": $lon, "picture": $picture, "starts_at": $starts_at, "time_zone": $time_zone, "title": $title, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List your own maps
#
# GET /maps
export def "maps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/maps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create map
#
# POST /maps
# --map_settings shape: {editor_access?: string, respotting_to_this_map?: bool, visitor_access?: string}
export def "maps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. A collection of restaurants, cafes, clubs and random spots that I recommend in Berlin
  --map-settings: any # shape: {editor_access?: string, respotting_to_this_map?: bool, visitor_access?: string}
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --title: string # e.g. My favourite places in Berlin
  --visibility: string@visibility-completer # e.g. public
]: any -> record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/maps")
  let req_body = {"description": $description, "map_settings": $map_settings, "picture": $picture, "title": $title, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Search maps
#
# GET /maps/search
export def "maps-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query
  --d: int # Distance. Diameter of search radius in meter (default: 2000 meter)
  --lat: float # Latitude for search radius (default distance: 2000 meter)
  --lon: float # Longitude for search radius (default distance: 2000 meter)
]: nothing -> record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "d" $d "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/maps/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete map
#
# DELETE /maps/{id}
export def "maps delete" [
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
]: nothing -> record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get map
#
# GET /maps/{id}
export def "maps get" [
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
]: nothing -> record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, relation: record<access: string, access_group: string, subscribed: bool>, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update map
#
# PATCH /maps/{id}
# --map_settings shape: {editor_access?: string, respotting_to_this_map?: bool, visitor_access?: string}
export def "maps update" [
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
  --description: string # e.g. A collection of restaurants, cafes, clubs and random spots that I recommend in Berlin
  --map-settings: any # shape: {editor_access?: string, respotting_to_this_map?: bool, visitor_access?: string}
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --title: string # e.g. My favourite places in Berlin
  --visibility: string@visibility-completer # e.g. public
]: any -> record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}"))
  let req_body = {"description": $description, "map_settings": $map_settings, "picture": $picture, "title": $title, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List attachments for a given map
#
# GET /maps/{id}/attachments
export def "maps-attachments get" [
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
]: nothing -> table<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, status: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload map attachment
#
# POST /maps/{id}/attachments
export def "maps-attachments create" [
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
  --body: string
]: any -> record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/attachments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List collaborators of a map
#
# GET /maps/{id}/collaborators/
export def "maps-collaborators get" [
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
]: nothing -> table<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/collaborators/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete collaboration
#
# DELETE /maps/{id}/collaborators/{user_id}
export def "maps-collaborators delete" [
  id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/maps/{id}/collaborators/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update collaborator
#
# PATCH /maps/{id}/collaborators/{user_id}
export def "maps-collaborators update" [
  id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: string@group-completer # e.g. editor
]: any -> record<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/maps/{id}/collaborators/{user_id}"))
  let req_body = {"group": $group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List comments for a given map
#
# GET /maps/{id}/comments
export def "maps-comments get" [
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
]: nothing -> table<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create map comment
#
# POST /maps/{id}/comments
export def "maps-comments create" [
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
  --body: string # e.g. Nice photo
]: any -> record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/comments"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List respots of a map
#
# GET /maps/{id}/respots
export def "maps-respots get" [
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
]: nothing -> table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/respots"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List spots for a given map
#
# GET /maps/{id}/spots
export def "maps-spots list" [
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
  --order: string@order-completer # Order of spots
]: nothing -> table<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/spots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create spot
#
# POST /maps/{id}/spots
export def "maps-spots create" [
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
  --description: string # e.g. Landed here by accident but look how wonderful this place is in the photos attached
  --lat: float # e.g. 53.112385
  --lon: float # e.g. 10.58349
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --time-zone: string # e.g. Berlin
  --title: string # e.g. Beautiful place out in the country
]: any -> record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/spots"))
  let req_body = {"description": $description, "lat": $lat, "lon": $lon, "picture": $picture, "time_zone": $time_zone, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Unsubscribe from map
#
# DELETE /maps/{id}/subscriptions
export def "maps-subscriptions delete" [
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
]: nothing -> record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/subscriptions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List subscriptions for a given map
#
# GET /maps/{id}/subscriptions
export def "maps-subscriptions get" [
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
]: nothing -> table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/maps/{id}/subscriptions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get spot
#
# GET /maps/{map_id}/spots/{id}
export def "maps-spots get" [
  map_id: int
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
]: nothing -> record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({map_id: (encode-path-segment $map_id), id: (encode-path-segment $id)} | format pattern "/maps/{map_id}/spots/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete respot from map by spot id
#
# DELETE /maps/{map_id}/spots/{spot_id}/respot
export def "maps-spots-respot delete" [
  map_id: int
  spot_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({map_id: (encode-path-segment $map_id), spot_id: (encode-path-segment $spot_id)} | format pattern "/maps/{map_id}/spots/{spot_id}/respot"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List maps that user can respot to
#
# GET /respot_maps
export def "respot-maps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/respot_maps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete respot
#
# DELETE /respots/{id}
export def "respots delete" [
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
]: nothing -> record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/respots/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get respot
#
# GET /respots/{id}
export def "respots get" [
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
]: nothing -> record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/respots/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get secret access token to share map
#
# GET /share/map/{id}
export def "share-map get" [
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
]: nothing -> record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, owner_id: int, picture_url: string, title: string, token: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/share/map/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List your own spots
#
# GET /spots
export def "spots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # Order of spots
]: nothing -> table<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search spots
#
# GET /spots/search
export def "spots-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query
  --d: int # Distance. Diameter of search radius in meter (default: 2000 meter)
  --lat: float # Latitude for search radius (2 km)
  --lon: float # Longitude for search radius (2 km)
]: nothing -> record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "d" $d "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spots/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete spot
#
# DELETE /spots/{id}
export def "spots delete" [
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
]: nothing -> record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update spot
#
# PATCH /spots/{id}
export def "spots update" [
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
  --description: string # e.g. Landed here by accident but look how wonderful this place is in the photos attached
  --lat: float # e.g. 53.112385
  --lon: float # e.g. 10.58349
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --time-zone: string # e.g. Berlin
  --title: string # e.g. Beautiful place out in the country
]: any -> record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}"))
  let req_body = {"description": $description, "lat": $lat, "lon": $lon, "picture": $picture, "time_zone": $time_zone, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List attachments for a given spot
#
# GET /spots/{id}/attachments
export def "spots-attachments get" [
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
]: nothing -> table<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, status: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload spot attachment
#
# POST /spots/{id}/attachments
export def "spots-attachments create" [
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
  --body: string
]: any -> record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/attachments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List comments for a given spot
#
# GET /spots/{id}/comments
export def "spots-comments get" [
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
]: nothing -> table<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create spot comment
#
# POST /spots/{id}/comments
export def "spots-comments create" [
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
  --body: string # e.g. Nice photo
]: any -> record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/comments"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List events for a given spot
#
# GET /spots/{id}/events
export def "spots-events get" [
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
  --timeframe-start: string # Begin of time range of event (ISO 8601 date format).
  --timeframe-end: string # End of time range of event (ISO 8601 date format).
  --bounds: string # To refine your event index request to contain only events within a geographical box pass the followng bounds parameters. F. e. to get events within 'Hamburg, St. Pauli': bounds[sw_lat]=53.54831449741324 bounds[sw_lon]=9.943227767944336 bounds[ne_lat]=53.5571103674878 bounds[ne_lon]=9.9776029586792
]: nothing -> table<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe_start" $timeframe_start "scalar") (serialize-qp "timeframe_end" $timeframe_end "scalar") (serialize-qp "bounds" $bounds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create event
#
# POST /spots/{id}/events
export def "spots-events create" [
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
  --description: string # e.g. Very special event
  --ends-at: string # format: date-time
  --lat: float # e.g. 53.293493
  --lon: float # e.g. 12.394328
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --starts-at: string # format: date-time
  --time-zone: string # e.g. Berlin
  --title: string # e.g. 20th anniversary event
  --user-id: int # e.g. 703943
]: any -> record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/events"))
  let req_body = {"description": $description, "ends_at": $ends_at, "lat": $lat, "lon": $lon, "picture": $picture, "starts_at": $starts_at, "time_zone": $time_zone, "title": $title, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Respot a spot onto a map
#
# POST /spots/{id}/respots
export def "spots-respots create" [
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
  --body: float
]: any -> record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spots/{id}/respots"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List subscriptions. Pass no parameters to get own subscriptions
#
# GET /subscriptions
export def "subscriptions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # Id of user
  --map-id: int # Id of map
]: nothing -> table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "map_id" $map_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create map subscription
#
# POST /subscriptions
export def "subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: float
]: any -> record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List latest maps
#
# GET /trends/latest
export def "trends-latest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trends/latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List recommended maps
#
# GET /trends/recommended
export def "trends-recommended get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trends/recommended")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search users
#
# GET /users/search
export def "users-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query
]: nothing -> record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get user profile
#
# GET /users/{id}
export def "users get" [
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
]: nothing -> record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List maps for a given user
#
# GET /users/{user_id}/maps
export def "users-maps get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/maps"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
