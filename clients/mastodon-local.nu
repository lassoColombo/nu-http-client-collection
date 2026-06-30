# Auto-generated client for Mastodon API Specification (https://github.com/mastodon/mastodon) v1.0
# Source: https://api.apis.guru/v2/specs/mastodon.local/1.0/openapi.json
# Auth: --token flag or $env.MASTODON_API_SPECIFICATION_HTTPS_GITHUB_COM_MASTODON_MASTODON_TOKEN

const BASE_URL = "http://mastodon.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MASTODON_API_SPECIFICATION_HTTPS_GITHUB_COM_MASTODON_MASTODON_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://mastodon.local" "https://mastodon.social"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["disable" "none" "silence" "suspend"] }
def order-completer [] { ["active" "new"] }
def replies-policy-completer [] { ["followed" "list" "none"] }
def type-completer-1 [] { ["accounts" "hashtags" "statuses"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "oembed get" } } | get name | first)
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

# OEmbed as JSON
#
# GET /api/oembed
export def "oembed get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # URL of a status
  --maxwidth: int # width of the iframe. Defaults to 400 (default: 400)
  --maxheight: int # height of the iframe. Defaults to null
]: nothing -> record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "maxwidth" $maxwidth "scalar") (serialize-qp "maxheight" $maxheight "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oembed" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"url": $url, "maxwidth": $maxwidth, "maxheight": $maxheight} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View identity proof
#
# GET /api/proofs
export def "proofs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider: string # The identity provider to be looked up. Currently only supports keybase (case-sensitive)
  --username: string # The username on the selected identity provider
]: nothing -> record<profile_url: string, proof_url: string, provider: string, provider_username: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider" $provider "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/proofs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"provider": $provider, "username": $username} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a user and account records. Returns an account access token for the app that initiated the request. The app should save this token for later, and should wait for the user to confirm their account by clicking a link in their email inbox.
#
# POST /api/v1/accounts
export def "accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sets a private note on a user.
#
# GET /api/v1/accounts/relationships
export def "accounts-relationships get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Array of account IDs to check
]: nothing -> table<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts/relationships" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Search for matching accounts by username or display name.
#
# GET /api/v1/accounts/search
export def "accounts-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # What to search for
  --limit: int # Maximum number of results. Defaults to 40. (default: 40)
  --resolve: string # Attempt WebFinger lookup. Defaults to false. Use this when `q` is an exact address.
  --following: oneof<nothing, bool> # Only who the user is following. Defaults to false.
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "resolve" $resolve "scalar") (serialize-qp "following" $following "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "limit": $limit, "resolve": $resolve, "following": $following} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the user's display and preferences.
#
# PATCH /api/v1/accounts/update_credentials
export def "accounts-update-credentials update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/update_credentials" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Test to make sure that the user token works.
#
# GET /api/v1/accounts/verify_credentials
export def "accounts-verify-credentials get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/accounts/verify_credentials" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# GET /api/v1/accounts/{id}
export def "accounts get" [
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
]: nothing -> record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Block the given account. Clients should filter statuses from this account if received (e.g. due to a boost in the Home timeline).
#
# POST /api/v1/accounts/{id}/block
export def "accounts-block create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/block") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Tags featured by this account.
#
# GET /api/v1/accounts/{id}/featured_tags
export def "accounts-featured-tags get" [
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
]: nothing -> table<id: string, last_status_at: string, name: string, statuses_count: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/featured_tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Follow the given account. Can also be used to update whether to show reblogs or enable notifications.
#
# POST /api/v1/accounts/{id}/follow
export def "accounts-follow create" [
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
  --body: any
]: any -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/follow") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Accounts which follow the given account, if network is not hidden by the account owner.
#
# GET /api/v1/accounts/{id}/followers
export def "accounts-followers get" [
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
  --max-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --since-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --limit: int # Maximum number of results to return. Defaults to 40. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/followers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max_id": $max_id, "since_id": $since_id, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Accounts which the given account is following, if network is not hidden by the account owner.
#
# GET /api/v1/accounts/{id}/following
export def "accounts-following get" [
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
  --max-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --since-id: string # Internal parameter. Use HTTP `Link` header for pagination.
  --limit: int # Maximum number of results to return. Defaults to 40. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/following") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max_id": $max_id, "since_id": $since_id, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Array of IdentityProof
#
# GET /api/v1/accounts/{id}/identity_proofs
export def "accounts-identity-proofs get" [
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
]: nothing -> table<profile_url: string, proof_url: string, provider: string, provider_username: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/identity_proofs") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# User lists that you have added this account to.
#
# GET /api/v1/accounts/{id}/lists
export def "accounts-lists get" [
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
]: nothing -> table<id: string, replies_policy: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/lists") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Mute the given account. Clients should filter statuses and notifications from this account, if received (e.g. due to a boost in the Home timeline).
#
# POST /api/v1/accounts/{id}/mute
export def "accounts-mute create" [
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
  --body: any
]: any -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/mute") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sets a private note on a user.
#
# POST /api/v1/accounts/{id}/note
export def "accounts-note create" [
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
  --body: any
]: any -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/note") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add the given account to the user's featured profiles. (Featured profiles are currently shown on the user's own public profile.)
#
# POST /api/v1/accounts/{id}/pin
export def "accounts-pin create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/pin") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Statuses posted to the given account.
#
# GET /api/v1/accounts/{id}/statuses
export def "accounts-statuses get" [
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
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/statuses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Block the given account. Clients should filter statuses from this account if received (e.g. due to a boost in the Home timeline).
#
# POST /api/v1/accounts/{id}/unblock
export def "accounts-unblock create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/unblock") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Unfollow the given account.
#
# POST /api/v1/accounts/{id}/unfollow
export def "accounts-unfollow create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/unfollow") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Unmute the given account.
#
# POST /api/v1/accounts/{id}/unmute
export def "accounts-unmute create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/unmute") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Remove the given account from the user's featured profiles.
#
# POST /api/v1/accounts/{id}/unpin
export def "accounts-unpin create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/accounts/{id}/unpin") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# View accounts matching certain criteria for filtering, up to 100 at a time. Pagination may be done with the HTTP Link header in the response.
#
# GET /api/v1/admin/accounts
export def "admin-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Filter for local accounts?
  --remote: oneof<nothing, bool> # Filter for remote accounts?
  --by-domain: string # Filter by the given domain
  --active: oneof<nothing, bool> # Filter for currently active accounts?
  --pending: oneof<nothing, bool> # Filter for currently pending accounts?
  --disabled: oneof<nothing, bool> # Filter for currently disabled accounts?
  --silenced: oneof<nothing, bool> # Filter for currently silenced accounts?
  --suspended: oneof<nothing, bool> # Filter for currently suspended accounts?
  --staff: oneof<nothing, bool> # Filter for staff accounts?
  --username: string # Username to search for
  --display-name: string # Display name to search for
  --email: string # Lookup a user with this email
  --ip: string # Lookup a user with this IP
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, locale: string, role: string, silenced: bool, suspended: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "local" $local "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "by_domain" $by_domain "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "pending" $pending "scalar") (serialize-qp "disabled" $disabled "scalar") (serialize-qp "silenced" $silenced "scalar") (serialize-qp "suspended" $suspended "scalar") (serialize-qp "staff" $staff "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "display_name" $display_name "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/accounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"local": $local, "remote": $remote, "by_domain": $by_domain, "active": $active, "pending": $pending, "disabled": $disabled, "silenced": $silenced, "suspended": $suspended, "staff": $staff, "username": $username, "display_name": $display_name, "email": $email, "ip": $ip} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View admin-level information about the given account.
#
# GET /api/v1/admin/accounts/{id}
export def "admin-accounts get" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, approved: bool, confirmed: bool, created_at: string, created_by_application_id: string, disabled: bool, email: string, id: string, invite_request: string, invited_by_account_id: string, ip: string, locale: string, role: string, silenced: bool, suspended: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/accounts/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Perform an action against an account and log this action in the moderation history.
#
# POST /api/v1/admin/accounts/{id}/action
export def "admin-accounts-action create" [
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
  --report-id: string # ID of an associated report that caused this action to be taken
  --send-email-notification: oneof<nothing, bool> # Whether an email should be sent to the user with the above information.
  --text: string # Additional text for clarification of why this action was taken
  --type: string@type-completer # Type of action to be taken. Enumerable oneOf: none disable silence suspend
  --warning-preset-id: string # ID of a preset warning
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/accounts/{id}/action") $auth.query)
  let req_body = {"report_id": $report_id, "send_email_notification": $send_email_notification, "text": $text, "type": $type, "warning_preset_id": $warning_preset_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Approve the given local account if it is currently pending approval.
#
# POST /api/v1/admin/accounts/{id}/approve
export def "admin-accounts-approve create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/accounts/{id}/approve") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Re-enable a local account whose login is currently disabled.
#
# POST /api/v1/admin/accounts/{id}/enable
export def "admin-accounts-enable create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/accounts/{id}/enable") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Reject the given local account if it is currently pending approval.
#
# POST /api/v1/admin/accounts/{id}/reject
export def "admin-accounts-reject create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/accounts/{id}/reject") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Unsilence a currently silenced account.
#
# POST /api/v1/admin/accounts/{id}/unsilence
export def "admin-accounts-unsilence create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/accounts/{id}/unsilence") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Unsuspend a currently suspended account.
#
# POST /api/v1/admin/accounts/{id}/unsuspend
export def "admin-accounts-unsuspend create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/accounts/{id}/unsuspend") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# View all reports. Pagination may be done with HTTP Link header in the response.
#
# GET /api/v1/admin/reports
export def "admin-reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resolved: oneof<nothing, bool>
  --account-id: string
  --target-account-id: string
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: list<record>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolved" $resolved "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "target_account_id" $target_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/admin/reports" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"resolved": $resolved, "account_id": $account_id, "target_account_id": $target_account_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View information about the report with the given ID.
#
# GET /api/v1/admin/reports/{id}
export def "admin-reports get" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/reports/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Claim the handling of this report to yourself.
#
# POST /api/v1/admin/reports/{id}/assign_to_self
export def "admin-reports-assign-to-self create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/reports/{id}/assign_to_self") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Mark a report as resolved with no further action taken.
#
# POST /api/v1/admin/reports/{id}/reopen
export def "admin-reports-reopen create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/reports/{id}/reopen") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Mark a report as resolved with no further action taken.
#
# POST /api/v1/admin/reports/{id}/resolve
export def "admin-reports-resolve create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/reports/{id}/resolve") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Unassign a report so that someone else can claim it.
#
# POST /api/v1/admin/reports/{id}/unassign
export def "admin-reports-unassign create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, action_taken: string, assigned_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, comment: string, created_at: string, id: string, statuses: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/admin/reports/{id}/unassign") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# See all currently active announcements set by admins.
#
# GET /api/v1/announcements
export def "announcements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-dismissed: oneof<nothing, bool> # If true, response will include announcements dismissed by the user. Defaults to false.
]: nothing -> table<all_day: bool, created_at: string, ends_at: string, id: string, published: bool, read: bool, scheduled_at: string, starts_at: string, text: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_dismissed" $with_dismissed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/announcements" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"with_dismissed": $with_dismissed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows a user to mark the announcement as read.
#
# POST /api/v1/announcements/{id}/dismiss
export def "announcements-dismiss create" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/announcements/{id}/dismiss") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Undo a react emoji to an announcement.
#
# DELETE /api/v1/announcements/{id}/reactions/{name}
export def "announcements-reactions delete" [
  id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), name: (encode-path-segment $name)} | format pattern "/api/v1/announcements/{id}/reactions/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Allows a user to mark the announcement as read.
#
# PUT /api/v1/announcements/{id}/reactions/{name}
export def "announcements-reactions update" [
  id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), name: (encode-path-segment $name)} | format pattern "/api/v1/announcements/{id}/reactions/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Create a new application to obtain OAuth2 credentials.
#
# POST /api/v1/apps
export def "apps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<client_id: string, client_secret: string, id: string, name: string, redirect_uri: string, vapid_key: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/apps" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Confirm that the app's OAuth2 credentials work.
#
# GET /api/v1/apps/verify_credentials
export def "apps-verify-credentials get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/apps/verify_credentials" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get blocked users.
#
# GET /api/v1/blocks
export def "blocks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --max-id: string
  --since-id: string
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/blocks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Statuses the user has bookmarked.
#
# GET /api/v1/bookmarks
export def "bookmarks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --max-id: string
  --since-id: string
  --min-id: string
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/bookmarks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Show conversation.
#
# GET /api/v1/conversations
export def "conversations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> table<accounts: list<record>, id: string, last_status: record<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, unread: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/conversations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove converstation
#
# DELETE /api/v1/conversations/{id}
export def "conversations delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/conversations/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Remove converstation
#
# POST /api/v1/conversations/{id}/read
export def "conversations-read create" [
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
]: nothing -> record<accounts: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, id: string, last_status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, unread: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/conversations/{id}/read") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns custom emojis that are available on the server.
#
# GET /api/v1/custom_emojis
export def "custom-emojis get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/custom_emojis" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# List accounts visible in the directory.
#
# GET /api/v1/directory
export def "directory get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # How many accounts to load. Default 40. (default: 40)
  --offset: int # How many accounts to skip before returning results. Default 0. (default: 0)
  --order: string@order-completer # the `active` to sort by most recently posted statuses (default) or `new` to sort by most recently created profiles. (default: active)
  --local: oneof<nothing, bool> # Only return local accounts.
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "local" $local "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/directory" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "order": $order, "local": $local} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove a domain block, if it exists in the user's array of blocked domains.
#
# DELETE /api/v1/domain_blocks
export def "domain-blocks delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # Domain to unblock.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/domain_blocks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"domain": $domain} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# View domains the user has blocked.
#
# GET /api/v1/domain_blocks
export def "domain-blocks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --max-id: string
  --since-id: string
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/domain_blocks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# "Block a domain to: - hide all public posts from it - hide all notifications from it - remove all followers from it - prevent following new users from it (but does not remove existing follows)"
#
# POST /api/v1/domain_blocks
export def "domain-blocks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/domain_blocks" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Accounts that the user is currently featuring on their profile.
#
# GET /api/v1/endorsements
export def "endorsements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return. Defaults to 40. Paginate using the HTTP Link header. (default: 40)
  --max-id: string # Internal parameter. Use HTTP Link header from response for pagination
  --since-id: string # Internal parameter. Use HTTP Link header from response for pagination.
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/endorsements" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Statuses the user has favourited.
#
# GET /api/v1/favourites
export def "favourites get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --max-id: string
  --min-id: string
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/favourites" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View your featured tags.
#
# GET /api/v1/featured_tags
export def "featured-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, last_status_at: string, name: string, statuses_count: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/featured_tags" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Create a feature a tag.
#
# POST /api/v1/featured_tags
export def "featured-tags create" [
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
]: any -> record<id: string, last_status_at: string, name: string, statuses_count: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/featured_tags" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Shows your 10 most-used tags, with usage history for the past week.
#
# GET /api/v1/featured_tags/suggestions
export def "featured-tags-suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, last_status_at: string, name: string, statuses_count: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/featured_tags/suggestions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Unfeature a tag
#
# DELETE /api/v1/featured_tags/{id}
export def "featured-tags delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/featured_tags/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# GET /api/v1/filters
export def "filters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/filters" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# POST /api/v1/filters
export def "filters create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/filters" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a filter.
#
# DELETE /api/v1/filters/{id}
export def "filters delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/filters/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get one filter.
#
# GET /api/v1/filters/{id}
export def "filters get" [
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
]: nothing -> record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/filters/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Update a filter.
#
# PUT /api/v1/filters/{id}
export def "filters update" [
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
  --body: any
]: any -> record<context: list<string>, expires_at: string, id: string, irreversible: bool, phrase: string, whole_word: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/filters/{id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Pending Follows
#
# GET /api/v1/follow_requests
export def "follow-requests get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return. Defaults to 40. Paginate using the HTTP Link header. (default: 40)
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/follow_requests" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Accept Follow
#
# POST /api/v1/follow_requests/{id}/authorize
export def "follow-requests-authorize create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/follow_requests/{id}/authorize") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Accept Follow
#
# POST /api/v1/follow_requests/{id}/reject
export def "follow-requests-reject create" [
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
]: nothing -> record<blocked_by: bool, blocking: bool, domain_blocking: bool, endorsed: bool, followed_by: bool, following: bool, id: string, muting: bool, muting_notifications: bool, note: string, notifying: bool, requested: bool, showing_reblogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/follow_requests/{id}/reject") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Information about the server.
#
# GET /api/v1/instance
export def "instance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<approval_required: bool, contact_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, description: string, email: string, invites_enabled: bool, languages: list<string>, registrations: bool, short_description: string, stats: record, thumbnail: string, title: string, uri: string, urls: record, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Instance activity over the last 3 months, binned weekly.
#
# GET /api/v1/instance/activity
export def "instance-activity get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<logins: string, registrations: string, statuses: string, week: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/activity" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Information about the server.
#
# GET /api/v1/instance/peers
export def "instance-peers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/peers" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Delete a list
#
# DELETE /api/v1/lists
export def "lists delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/lists" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Fetch all lists that the user owns.
#
# GET /api/v1/lists
export def "lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, replies_policy: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/lists" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Create a new list.
#
# POST /api/v1/lists
export def "lists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replies-policy: string@replies-policy-completer # Enumerable oneOf followed list none. Defaults to list. (default: list)
  title: string # The title of the list to be created.
]: any -> record<id: string, replies_policy: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/lists" $auth.query)
  let req_body = {"replies_policy": $replies_policy, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Change the title of a list, or which replies to show.
#
# PUT /api/v1/lists
export def "lists update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replies-policy: string@replies-policy-completer # Enumerable oneOf followed list none. Defaults to list. (default: list)
  --title: string # The title of the list to be created.
]: any -> record<id: string, replies_policy: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/lists" $auth.query)
  let req_body = {"replies_policy": $replies_policy, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Remove converstation
#
# GET /api/v1/lists/{id}
export def "lists get" [
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
]: nothing -> record<id: string, replies_policy: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/lists/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Remove accounts from the given list.
#
# DELETE /api/v1/lists/{id}/accounts
export def "lists-accounts delete" [
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
  --account-ids: list<string> # Array of account IDs to add to the list.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "account_ids" $account_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/lists/{id}/accounts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"account_ids": $account_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# View accounts in List
#
# GET /api/v1/lists/{id}/accounts
export def "lists-accounts get" [
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
  --limit: int # Maximum number of results. Defaults to 40. Max 40. Set to 0 in order to get all accounts without pagination. Pagination is done with the HTTP Link header. (default: 40)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/lists/{id}/accounts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add accounts to the given list. Note that the user must be following these accounts.
#
# POST /api/v1/lists/{id}/accounts
export def "lists-accounts create" [
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
  account_ids: list<string> # Array of account IDs to add to the list.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/lists/{id}/accounts") $auth.query)
  let req_body = {"account_ids": $account_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get saved timeline position
#
# GET /api/v1/markers
export def "markers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeline: list # Array of markers to fetch. String enum anyOf home, notifications. If not provided, an empty object will be returned.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeline" $timeline "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/markers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeline": $timeline} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get saved timeline position
#
# POST /api/v1/markers
export def "markers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/markers" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an attachment to be used with a new status.
#
# POST /api/v1/media
export def "media create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/media" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get an attachement.
#
# GET /api/v1/media/{id}
export def "media get" [
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
]: nothing -> record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/media/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-get $req $insecure $raw $allow_errors $full [200 206]
}

# Update an Attachment, before it is attached to a status and posted.
#
# POST /api/v1/media/{id}
export def "media create-by-id" [
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
  --body: any
]: any -> record<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/media/{id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Accounts the user has muted.
#
# GET /api/v1/mutes
export def "mutes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --max-id: string
  --since-id: string
]: nothing -> table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/mutes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Notifications concerning the user. This API returns Link headers containing links to the next/previous page. However, the links can also be constructed dynamically using query params and id values.
#
# GET /api/v1/notifications
export def "notifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
  --exclude-types: list<string> # Array of types to exclude (follow, favourite, reblog, mention, poll, follow_request)
  --account-id: string # Return only notifications received from this account
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "exclude_types" $exclude_types "multi") (serialize-qp "account_id" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/notifications" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id, "exclude_types": $exclude_types, "account_id": $account_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Clear all notifications from the server.
#
# POST /api/v1/notifications/clear
export def "notifications-clear create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notifications/clear" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# View information about a notification with a given ID.
#
# GET /api/v1/notifications/{id}
export def "notifications get" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/notifications/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Clear a single notification from the server.
#
# POST /api/v1/notifications/{id}/dismiss
export def "notifications-dismiss create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, created_at: string, id: string, status: record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/notifications/{id}/dismiss") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# View a poll.
#
# GET /api/v1/polls/{id}
export def "polls get" [
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
]: nothing -> record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/polls/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Vote on a poll.
#
# POST /api/v1/polls/{id}
export def "polls create" [
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
  choices: list<string>
]: any -> record<emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/polls/{id}") $auth.query)
  let req_body = {"choices": $choices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Shows your 10 most-used tags, with usage history for the past week.
#
# GET /api/v1/preferences
export def "preferences get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<posting_default_language: string, posting_default_sensitive: bool, posting_default_visibility: string, reading_expand_media: string, reading_expand_spoilers: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/preferences" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Updates the current push subscription. Only the data part can be updated. To change fundamentals, a new subscription must be created instead.
#
# DELETE /api/v1/push/subscription
export def "push-subscription delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push/subscription" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# View the PushSubscription currently associated with this access token.
#
# GET /api/v1/push/subscription
export def "push-subscription get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alerts: record, endpoint: string, id: string, server_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push/subscription" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Add a Web Push API subscription to receive notifications. Each access token can have one push subscription. If you create a new subscription, the old subscription is deleted.
#
# POST /api/v1/push/subscription
export def "push-subscription create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: string
  subscription: string
]: any -> record<alerts: record, endpoint: string, id: string, server_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push/subscription" $auth.query)
  let req_body = {"data": $data, "subscription": $subscription} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the current push subscription. Only the data part can be updated. To change fundamentals, a new subscription must be created instead.
#
# PUT /api/v1/push/subscription
export def "push-subscription update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: string
]: any -> record<alerts: record, endpoint: string, id: string, server_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push/subscription" $auth.query)
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# File a report.
#
# POST /api/v1/reports
export def "reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # ID of the account to report
  --comment: string # Reason for the report (default max 1000 characters)
  --forward: oneof<nothing, bool> # If the account is remote, should the report be forwarded to the remote admin?
  --status-ids: list<string> # Array of Statuses to attach to the report, for context
]: any -> record<action_taken: bool, action_taken_at: string, category: string, comment: string, created_at: string, forwarded: bool, id: string, rule_ids: list<int>, status_ids: list<int>, target_account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/reports" $auth.query)
  let req_body = {"account_id": $account_id, "comment": $comment, "forward": $forward, "status_ids": $status_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# View scheduled statuses
#
# GET /api/v1/scheduled_statuses
export def "scheduled-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> table<id: string, media_attachments: list<record>, params: record<application_id: string, in_reply_to_id: string, media_ids: list, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/scheduled_statuses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cancel a scheduled status
#
# DELETE /api/v1/scheduled_statuses/{id}
export def "scheduled-statuses delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/scheduled_statuses/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# View a single scheduled status
#
# GET /api/v1/scheduled_statuses/{id}
export def "scheduled-statuses get" [
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
]: nothing -> record<id: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, in_reply_to_id: string, media_ids: list<string>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/scheduled_statuses/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# View a single scheduled status
#
# PUT /api/v1/scheduled_statuses/{id}
export def "scheduled-statuses update" [
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
  --scheduled-at: string # ISO 8601 Datetime at which the status will be published. Must be at least 5 minutes into the future. (format: date-time)
]: any -> record<id: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, params: record<application_id: string, in_reply_to_id: string, media_ids: list<string>, scheduled_at: string, sensitive: bool, spoiler_text: string, text: string, visibility: string>, scheduled_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/scheduled_statuses/{id}") $auth.query)
  let req_body = {"scheduled_at": $scheduled_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# POST /api/v1/statuses
export def "statuses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # Prevent duplicate submissions of the same status. Idempotency keys are stored for up to 1 hour, and can be any arbitrary string. Consider using a hash or UUID generated client-side.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/statuses" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Idempotency-Key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# DELETE /api/v1/statuses/{id}
export def "statuses delete" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# GET /api/v1/statuses/{id}
export def "statuses get" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Privately bookmark a status.
#
# POST /api/v1/statuses/{id}/bookmark
export def "statuses-bookmark create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/bookmark") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# GET /api/v1/statuses/{id}/context
export def "statuses-context get" [
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
]: nothing -> record<ancestors: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, descendants: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/context") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Add a status to your favourites list.
#
# POST /api/v1/statuses/{id}/favourite
export def "statuses-favourite create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/favourite") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# View who favourited a given status.
#
# GET /api/v1/statuses/{id}/favourited_by
export def "statuses-favourited-by get" [
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
]: nothing -> record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/favourited_by") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Do not receive notifications for the thread that this status is part of. Must be a thread in which you are a participant.
#
# POST /api/v1/statuses/{id}/mute
export def "statuses-mute create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/mute") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Feature one of your own public statuses at the top of your profile.
#
# POST /api/v1/statuses/{id}/pin
export def "statuses-pin create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/pin") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Reshare a status.
#
# POST /api/v1/statuses/{id}/reblog
export def "statuses-reblog create" [
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
  --visibility: string # any visibility except limited or direct (i.e. public, unlisted, private). Defaults to public. Currently unused in UI.
]: any -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/reblog") $auth.query)
  let req_body = {"visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# View who boosted a given status.
#
# GET /api/v1/statuses/{id}/reblogged_by
export def "statuses-reblogged-by get" [
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
]: nothing -> record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/reblogged_by") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Remove a status from your private bookmarks.
#
# POST /api/v1/statuses/{id}/unbookmark
export def "statuses-unbookmark create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/unbookmark") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Remove a status from your favourites list.
#
# POST /api/v1/statuses/{id}/unfavourite
export def "statuses-unfavourite create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/unfavourite") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Status's conversation unmuted, or was already unmuted
#
# POST /api/v1/statuses/{id}/unmute
export def "statuses-unmute create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/unmute") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Unfeature a status from the top of your profile.
#
# POST /api/v1/statuses/{id}/unpin
export def "statuses-unpin create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/unpin") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Undo a reshare of a status.
#
# POST /api/v1/statuses/{id}/unreblog
export def "statuses-unreblog create" [
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
]: nothing -> record<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list<record>, fields: list<record>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: table<blurhash: string, description: string, id: string, meta: record, preview_url: string, remote_url: string, text_url: string, type: string, url: string>, mentions: table<acct: string, id: string, url: string, username: string>, muted: bool, pinned: bool, poll: record<emojis: list<record>, expired: bool, expires_at: string, id: string, multiple: bool, options: list<any>, own_votes: list<int>, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: table<history: list, name: string, url: string>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/statuses/{id}/unreblog") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Accounts the user has had past positive interactions with, but is not yet following.
#
# GET /api/v1/suggestions
export def "suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results to return. Defaults to 40. (default: 40)
]: nothing -> record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: table<category: string, shortcode: string, static_url: string, url: string, visible_in_picker: bool>, fields: table<name: string, value: string, verified_at: string>, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record<fields: list<record>, follow_requests_count: int, language: string, note: string, privacy: string, sensitive: bool>, statuses_count: int, suspended: bool, url: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/suggestions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete user suggestion
#
# DELETE /api/v1/suggestions/{id}
export def "suggestions delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/suggestions/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# View statuses from followed users.
#
# GET /api/v1/timelines/home
export def "timelines-home get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "local" $local "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/timelines/home" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"local": $local, "limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 206]
}

# View statuses in the given list timeline.
#
# GET /api/v1/timelines/list/{list_id}
export def "timelines-list get" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'list_id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/api/v1/timelines/list/{list_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Public timeline
#
# GET /api/v1/timelines/public
export def "timelines-public get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --remote: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --only-media: oneof<nothing, bool> # Show only statuses with media attached? Defaults to false.. (default: false)
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "local" $local "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "only_media" $only_media "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/timelines/public" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"local": $local, "remote": $remote, "only_media": $only_media, "limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View public statuses containing the given hashtag.
#
# GET /api/v1/timelines/tag/{hashtag}
export def "timelines-tag get" [
  hashtag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --remote: oneof<nothing, bool> # Show only local statuses? Defaults to false. (default: false)
  --only-media: oneof<nothing, bool> # Show only statuses with media attached? Defaults to false.. (default: false)
  --limit: int # Max number of results to return. Defaults to 20. (default: 20)
  --max-id: string # Return results older than ID
  --since-id: string # Return results newer than ID
  --min-id: string # Return results immediately newer than ID
]: nothing -> table<account: record<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, application: record<client_id: string, client_secret: string, name: string, vapid_key: string, website: string>, bookmarked: bool, card: record<author_name: string, author_url: string, blurhash: string, description: string, height: int, html: string, image: string, provider_name: string, provider_url: string, title: string, type: string, url: string, width: int>, content: string, created_at: string, emojis: list<record>, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list<record>, mentions: list<record>, muted: bool, pinned: bool, poll: record<emojis: list, expired: bool, expires_at: string, id: string, multiple: bool, options: list, own_votes: list, voted: bool, voters_count: int, votes_count: int>, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list<record>, text: string, uri: string, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hashtag | is-empty) { error make --unspanned { msg: "path parameter 'hashtag' must be non-empty" } }
  let qp = [(serialize-qp "local" $local "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "only_media" $only_media "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "min_id" $min_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({hashtag: (encode-path-segment $hashtag)} | format pattern "/api/v1/timelines/tag/{hashtag}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"local": $local, "remote": $remote, "only_media": $only_media, "limit": $limit, "max_id": $max_id, "since_id": $since_id, "min_id": $min_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Tags that are being used more frequently within the past week.
#
# GET /api/v1/trends
export def "trends get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Max number of results to return. Defaults to 10. (default: 10)
]: nothing -> table<history: list<record>, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/trends" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search results
#
# GET /api/v2/search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # What to search for
  --limit: int # Maximum number of results. Defaults to 40. (default: 20)
  --resolve: string # Attempt WebFinger lookup.
  --following: oneof<nothing, bool> # Only who the user is following. Defaults to false.
  --account-id: string # If provided, statuses returned will be authored only by this account
  --max-id: string # Return results older than this id
  --min-id: string # Return results immediately newer than this id
  --type: string@type-completer-1 # Enum(accounts, hashtags, statuses)
  --exclude-unreviewed: oneof<nothing, bool> # Filter out unreviewed tags? Defaults to false. Use true when trying to find trending tags.
  --offset: int # Offset in search results. Used for pagination. Defaults to 0.
]: nothing -> record<accounts: table<acct: string, avatar: string, avatar_static: string, bot: bool, created_at: string, discoverable: bool, display_name: string, emojis: list, fields: list, followers_count: int, following_count: int, header: string, header_static: string, id: string, last_status_at: string, locked: bool, moved: any, mute_expires_at: string, note: string, source: record, statuses_count: int, suspended: bool, url: string, username: string>, hashtags: table<account: record, application: record, bookmarked: bool, card: record, content: string, created_at: string, emojis: list, favourited: bool, favourites_count: int, id: string, in_reply_to_account_id: string, in_reply_to_id: string, language: string, media_attachments: list, mentions: list, muted: bool, pinned: bool, poll: record, reblog: any, reblogged: bool, reblogs_count: int, replies_count: int, sensitive: bool, spoiler_text: string, tags: list, text: string, uri: string, url: string, visibility: string>, statuses: table<history: list, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "resolve" $resolve "scalar") (serialize-qp "following" $following "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "exclude_unreviewed" $exclude_unreviewed "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "limit": $limit, "resolve": $resolve, "following": $following, "account_id": $account_id, "max_id": $max_id, "min_id": $min_id, "type": $type, "exclude_unreviewed": $exclude_unreviewed, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Displays an authorization form to the user. If approved, it will create and return an authorization code, then redirect to the desired redirect_uri, or show the authorization code if urn:ietf:wg:oauth:2.0:oob was requested. The authorization code can be used while requesting a token to obtain access to user-level methods.
#
# GET /oauth/authorize
export def "oauth-authorize get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # Should be set equal to code.
  --client-id: string # Client ID, obtained during app registration.
  --redirect-uri: string # Set a URI to redirect the user to. If this parameter is set to urn:ietf:wg:oauth:2.0:oob then the authorization code will be shown instead. Must match one of the redirect URIs declared during app registration.
  --scope: string # List of requested OAuth scopes, separated by spaces (or by pluses, if using query parameters). Must be a subset of scopes declared during app registration. If not provided, defaults to read.
  --force-login: oneof<nothing, bool> # Added in 2.6.0. Forces the user to re-login, which is necessary for authorizing with multiple accounts from the same instance.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "response_type" $response_type "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "force_login" $force_login "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/authorize" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"response_type": $response_type, "client_id": $client_id, "redirect_uri": $redirect_uri, "scope": $scope, "force_login": $force_login} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Revoke an access token to make it no longer valid for use.
#
# POST /oauth/revoke
export def "oauth-revoke create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/revoke" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns an access token, to be used during API calls that are not public.
#
# POST /oauth/token
export def "oauth-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<access_token: string, created_at: int, scope: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/form-data"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
