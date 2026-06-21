# Auto-generated client for Bufferapp v1
# Source: https://api.apis.guru/v2/specs/bufferapp.com/1/swagger.json
# Auth: --token flag or $env.BUFFERAPP_TOKEN

const BASE_URL = "https://api.bufferapp.com/1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUFFERAPP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.bufferapp.com/1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "info-configurationmedia-type-extension get" } } | get name | first)
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
export def "info-configurationmedia-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<media: record<picture_filetypes: list<string>, picture_size_max: float, picture_size_min: float>, services: record<appdotnet: record<types: record, urls: record>, facebook: record<types: record, urls: record>, google: record<types: record, urls: record>, linkedin: record<types: record, urls: record>, twitter: record<types: record, urls: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/info/configuration{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns an object with a the numbers of shares a link has had using Buffer.
#
# GET /links/shares{mediaTypeExtension}
export def "links-sharesmedia-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # URL-encoded URL of the page for which the number of shares is requested.
]: nothing -> record<shares: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let qp = [(serialize-qp "url" $url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/links/shares{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"url": $url} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/schedules/update{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns details of the posting schedules associated with a social media profile.
#
# GET /profiles/{id}/schedules{mediaTypeExtension}
export def "profiles-schedulesmedia-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<days: list<string>, times: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/schedules{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# "Returns an array of updates that are currently in the buffer for an individual social media profile.
#
# GET /profiles/{id}/updates/pending{mediaTypeExtension}
export def "profiles-updates-pendingmedia-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Specifies the page of status updates to receive. If not specified the first page of results will be returned.
  --count: int # Specifies the number of status updates to receive. If provided, must be between 1 and 100.
  --since: string # Specifies a unix timestamp which only status updates created after this time will be retrieved. (format: date)
  --utc: oneof<nothing, bool> # If utc is set times will be returned relative to UTC rather than the users associated timezone.
]: nothing -> record<total: float, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "utc" $utc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/pending{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "count": $count, "since": $since, "utc": $utc} | compact), body: null}
}

# Edit the order at which statuses for the specified social media profile will be sent out of the buffer.
#
# POST /profiles/{id}/updates/reorder{mediaTypeExtension}
export def "profiles-updates-reordermedia-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/reorder{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns an array of updates that have been sent from the buffer for an individual social media profile.
#
# GET /profiles/{id}/updates/sent{mediaTypeExtension}
export def "profiles-updates-sentmedia-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Specifies the page of status updates to receive. If not specified the first page of results will be returned.
  --count: int # Specifies the number of status updates to receive. If provided, must be between 1 and 100.
  --since: string # Specifies a unix timestamp which only status updates created after this time will be retrieved. (format: date)
  --utc: oneof<nothing, bool> # If utc is set times will be returned relative to UTC rather than the users associated timezone.
]: nothing -> record<total: float, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "utc" $utc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/sent{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "count": $count, "since": $since, "utc": $utc} | compact), body: null}
}

# Randomize the order at which statuses for the specified social media profile will be sent out of the buffer.
#
# POST /profiles/{id}/updates/shuffle{mediaTypeExtension}
export def "profiles-updates-shufflemedia-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}/updates/shuffle{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar: string, created_at: float, default: bool, formatted_username: string, id: string, schedules: table<days: list, times: list>, service: string, service_id: string, service_username: string, statistics: record<followers: float>, team_members: list<string>, timezone: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles/{id}{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns an array of social media profiles connected to a users account.
#
# GET /profiles{mediaTypeExtension}
export def "profilesmedia-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<_id: string, avatar: string, avatar_https: string, counts: record<daily_suggestions: float, drafts: float, pending: float, sent: float>, cover_photo: string, default: bool, disabled_features: list<any>, disconnected: string, formatted_service: string, formatted_username: string, has_used_suggestions: bool, id: string, schedules: list<record>, service: string, service_id: string, service_type: string, service_username: string, shortener: record<domain: string>, statistics: record<connections: float>, timezone: string, user_id: string, utm_tracking: string, verb: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/profiles{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<buffer_count: float, buffer_percentage: float, success: bool, updates: table<created_at: float, day: string, due_at: float, due_time: string, id: string, media: record, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/create{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/destroy{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the detailed information on individual interactions with the social media update such as favorites, retweets and likes.
#
# GET /updates/{id}/interactions{mediaTypeExtension}
export def "updates-interactionsmedia-type-extension get" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # Specifies a type of event to be retrieved, for example "retweet", "like", "comment", "mention" or "reshare". They can also be plural (e.g., "reshares"). Plurality has no effect other than visual semantics. See /info/configuration for more information on supported interaction events.
  --page: int # Specifies the page of status updates to receive. If not specified the first page of results will be returned.
  --count: int # Specifies the number of status updates to receive. If provided, must be between 1 and 100.
]: nothing -> record<interactions: table<_id: string, created_at: float, event: string, id: string, interaction_id: string, user: record>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/interactions{media_type_extension}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"event": $event, "page": $page, "count": $count} | compact), body: null}
}

# Move an existing status update to the top of the queue and recalculate times for all updates in the queue. Returns the update with its new posting time.
#
# POST /updates/{id}/move_to_top{mediaTypeExtension}
export def "updates-move-to-topmedia-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, sent_at: float, service_update_id: string, statistics: record<clicks: float, favorites: float, mentions: float, reach: float, retweets: float>, status: string, text: string, text_formatted: string, user_id: string, via: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/move_to_top{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Immediately shares a single pending update and recalculates times for updates remaining in the queue.
#
# POST /updates/{id}/share{mediaTypeExtension}
export def "updates-sharemedia-type-extension create" [
  id: string
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/share{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<buffer_count: float, buffer_percentage: float, success: bool, update: record<client_id: string, created_at: float, day: string, due_at: float, due_time: string, id: string, media: record<description: string, link: string, title: string>, profile_id: string, profile_service: string, status: string, text: string, text_formatted: string, user_id: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}/update{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: float, day: string, due_at: float, due_time: string, id: string, profile_id: string, profile_service: string, sent_at: float, service_update_id: string, statistics: record<clicks: float, favorites: float, mentions: float, reach: float, retweets: float>, status: string, text: string, text_formatted: string, user_id: string, via: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/updates/{id}{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a single user.
#
# GET /user{mediaTypeExtension}
export def "usermedia-type-extension get" [
  media_type_extension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, activity_at: float, created_at: float, id: string, plan: string, referral_link: string, referral_token: string, secret_email: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/user{media_type_extension}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
