# Auto-generated client for Bufferapp v1
# Source: https://api.apis.guru/v2/specs/bufferapp.com/1/swagger.json
# Auth: --token flag or $env.BUFFERAPP_TOKEN

const BASE_URL = "https://api.bufferapp.com/1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUFFERAPP_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.bufferapp.com/1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "info-configuration-media-type-extension get" } } | get name | first)
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

# Returns an object with the current configuration that Buffer is using, including supported services, their icons and the varying limits of character and schedules.
#
# GET /info/configuration{mediaTypeExtension}
export def "info-configuration-media-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<media: record<picture_filetypes: list<string>, picture_size_max: float, picture_size_min: float>, services: record<appdotnet: record<types: record, urls: record>, facebook: record<types: record, urls: record>, google: record<types: record, urls: record>, linkedin: record<types: record, urls: record>, twitter: record<types: record, urls: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/info/configuration{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an object with a the numbers of shares a link has had using Buffer.
#
# GET /links/shares{mediaTypeExtension}
export def "links-shares-media-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # URL-encoded URL of the page for which the number of shares is requested.
]: nothing -> record<shares: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/links/shares{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# "Set the posting schedules for the specified social media profile.
#
# POST /profiles/{id}/schedules/update{mediaTypeExtension}
export def "profiles-schedules-update-media-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/schedules/update{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns details of the posting schedules associated with a social media profile.
#
# GET /profiles/{id}/schedules{mediaTypeExtension}
export def "profiles-schedules-media-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<days: list<string>, times: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/schedules{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# "Returns an array of updates that are currently in the buffer for an individual social media profile.
#
# GET /profiles/{id}/updates/pending{mediaTypeExtension}
export def "profiles-updates-pending-media-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Specifies the page of status updates to receive. If not specified the first page of results will be returned.
  --count: int # Specifies the number of status updates to receive. If provided, must be between 1 and 100.
  --since: string # Specifies a unix timestamp which only status updates created after this time will be retrieved. (format: date)
  --utc: oneof<nothing, bool> # If utc is set times will be returned relative to UTC rather than the users associated timezone.
]: nothing -> record<total: float, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "utc" $utc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/pending{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit the order at which statuses for the specified social media profile will be sent out of the buffer.
#
# POST /profiles/{id}/updates/reorder{mediaTypeExtension}
export def "profiles-updates-reorder-media-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/reorder{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of updates that have been sent from the buffer for an individual social media profile.
#
# GET /profiles/{id}/updates/sent{mediaTypeExtension}
export def "profiles-updates-sent-media-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Specifies the page of status updates to receive. If not specified the first page of results will be returned.
  --count: int # Specifies the number of status updates to receive. If provided, must be between 1 and 100.
  --since: string # Specifies a unix timestamp which only status updates created after this time will be retrieved. (format: date)
  --utc: oneof<nothing, bool> # If utc is set times will be returned relative to UTC rather than the users associated timezone.
]: nothing -> record<total: float, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "utc" $utc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/sent{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Randomize the order at which statuses for the specified social media profile will be sent out of the buffer.
#
# POST /profiles/{id}/updates/shuffle{mediaTypeExtension}
export def "profiles-updates-shuffle-media-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/shuffle{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns details of the single specified social media profile.
#
# GET /profiles/{id}{mediaTypeExtension}
export def "profiles get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar: string, created_at: float, default: bool, formatted_username: string, id: string, schedules: table<days: list, times: list>, service: string, service_id: string, service_username: string, statistics: record<followers: float>, team_members: list<string>, timezone: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of social media profiles connected to a users account.
#
# GET /profiles{mediaTypeExtension}
export def "profiles-media-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<_id: string, avatar: string, avatar_https: string, counts: record<daily_suggestions: float, drafts: float, pending: float, sent: float>, cover_photo: string, default: bool, disabled_features: list<any>, disconnected: string, formatted_service: string, formatted_username: string, has_used_suggestions: bool, id: string, schedules: list<record>, service: string, service_id: string, service_type: string, service_username: string, shortener: record<domain: string>, statistics: record<connections: float>, timezone: string, user_id: string, utm_tracking: string, verb: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create one or more new status updates.
#
# POST /updates/create{mediaTypeExtension}
export def "updates-create-media-type-extension create" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<buffer_count: float, buffer_percentage: float, success: bool, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, media: record, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/create{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently delete an existing status update.
#
# POST /updates/{id}/destroy{mediaTypeExtension}
export def "updates-destroy-media-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/destroy{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the detailed information on individual interactions with the social media update such as favorites, retweets and likes.
#
# GET /updates/{id}/interactions{mediaTypeExtension}
export def "updates-interactions-media-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # Specifies a type of event to be retrieved, for example "retweet", "like", "comment", "mention" or "reshare". They can also be plural (e.g., "reshares"). Plurality has no effect other than visual semantics. See /info/configuration for more information on supported interaction events.
  --page: int # Specifies the page of status updates to receive. If not specified the first page of results will be returned.
  --count: int # Specifies the number of status updates to receive. If provided, must be between 1 and 100.
]: nothing -> record<interactions: table<_id: string, created_at: float, event: string, id: string, interaction_id: string, user: record>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/interactions{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move an existing status update to the top of the queue and recalculate times for all updates in the queue. Returns the update with its new posting time.
#
# POST /updates/{id}/move_to_top{mediaTypeExtension}
export def "updates-move-to-top-media-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, sent_at: float, service_update_id: string, statistics: record<clicks: float, favorites: float, mentions: float, reach: float, retweets: float>, status: string, text: string, text_formatted: string, user_id: string, via: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/move_to_top{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Immediately shares a single pending update and recalculates times for updates remaining in the queue.
#
# POST /updates/{id}/share{mediaTypeExtension}
export def "updates-share-media-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/share{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an existing, individual status update.
#
# POST /updates/{id}/update{mediaTypeExtension}
export def "updates-update-media-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<buffer_count: float, buffer_percentage: float, success: bool, update: record<client_id: string, created_at: float, day: string, due_at: float, due_time: string, id: string, media: record<description: string, link: string, title: string>, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/update{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single social media update.
#
# GET /updates/{id}{mediaTypeExtension}
export def "updates get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, sent_at: float, service_update_id: string, statistics: record<clicks: float, favorites: float, mentions: float, reach: float, retweets: float>, status: string, text: string, text_formatted: string, user_id: string, via: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single user.
#
# GET /user{mediaTypeExtension}
export def "user-media-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, activity_at: float, created_at: float, id: string, plan: string, referral_link: string, referral_token: string, secret_email: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/user{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
