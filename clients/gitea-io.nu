# Auto-generated client for Gitea API. v1.20.0+dev-93-g6886706f5
# Source: https://api.apis.guru/v2/specs/gitea.io/1.20.0+dev-93-g6886706f5/openapi.json
# Auth: --token flag or $env.GITEA_API_TOKEN

const BASE_URL = "http://localhost/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GITEA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-access_token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "access_token")=(encode-path-segment $token_val)", location: "query"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "sudo" => { {scheme: $scheme, headers: {Sudo: $token_val}, query: "", location: "header"} }
    "query-sudo" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "sudo")=(encode-path-segment $token_val)", location: "query"} }
    "x-gitea-otp" => { {scheme: $scheme, headers: {X-GITEA-OTP: $token_val}, query: "", location: "header"} }
    "query-token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "token")=(encode-path-segment $token_val)", location: "query"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
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

def base-url-completer [] { ["http://localhost/api/v1"] }
def auth-scheme-completer [] { ["query-access_token" "bearer" "basic" "sudo" "query-sudo" "x-gitea-otp" "query-token" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["dingtalk" "discord" "feishu" "gitea" "gogs" "msteams" "packagist" "slack" "telegram" "wechatwork"] }
def visibility-completer [] { ["limited" "private" "public"] }
def trust-model-completer [] { ["collaborator" "collaboratorcommitter" "committer" "default"] }
def permission-completer [] { ["admin" "read" "write"] }
def type-completer-1 [] { ["cargo" "chef" "composer" "conan" "conda" "container" "generic" "helm" "maven" "npm" "nuget" "pub" "pypi" "rubygems" "vagrant"] }
def service-completer [] { ["git" "gitea" "github" "gitlab"] }
def sort-completer [] { ["highestindex" "leastindex" "leastupdate" "oldest" "recentupdate"] }
def state-completer [] { ["error" "failure" "pending" "success" "warning"] }
def state-completer-1 [] { ["all" "closed" "open"] }
def type-completer-2 [] { ["issues" "pulls"] }
def state-completer-2 [] { ["closed" "open"] }
def sort-completer-1 [] { ["leastcomment" "leastupdate" "mostcomment" "oldest" "priority" "recentupdate"] }
def whitespace-completer [] { ["ignore-all" "ignore-change" "ignore-eol" "show-all"] }
def do-completer [] { ["manually-merged" "merge" "rebase" "rebase-merge" "squash"] }
def style-completer [] { ["merge" "rebase"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activitypub-user get-person" } } | get name | first)
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

# Returns the Person actor for a user
#
# GET /activitypub/user/{username}
# operationId: activitypubPerson
export def "activitypub-user get-person" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/activitypub/user/{username}") $auth.query)
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

# Send to the inbox
#
# POST /activitypub/user/{username}/inbox
# operationId: activitypubPersonInbox
export def "activitypub-user-inbox create-person" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/activitypub/user/{username}/inbox") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# List cron tasks
#
# GET /admin/cron
# operationId: adminCronList
export def "admin-cron list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/cron" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Run cron task
#
# POST /admin/cron/{task}
# operationId: adminCronRun
export def "admin-cron create-run" [
  task: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($task | is-empty) { error make --unspanned { msg: "path parameter 'task' must be non-empty" } }
  let full_url = (build-url $base ({task: (encode-path-segment $task)} | format pattern "/admin/cron/{task}") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# List system's webhooks
#
# GET /admin/hooks
# operationId: adminListHooks
export def "admin-hooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/hooks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a hook
#
# POST /admin/hooks
# operationId: adminCreateHook
export def "admin-hooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string
  --branch-filter: string
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list<string>
  type: string@type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/hooks" $auth.query)
  let req_body = {"active": $active, "authorization_header": $authorization_header, "branch_filter": $branch_filter, "config": $config, "events": $events, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get a hook
#
# GET /admin/hooks/{id}
# operationId: adminGetHook
export def "admin-hooks get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/hooks/{id}") $auth.query)
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

# Update a hook
#
# PATCH /admin/hooks/{id}
# operationId: adminEditHook
export def "admin-hooks update-edit" [
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
  --active: oneof<nothing, bool>
  --authorization-header: string
  --branch-filter: string
  --config: record
  --events: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/admin/hooks/{id}") $auth.query)
  let req_body = {"active": $active, "authorization_header": $authorization_header, "branch_filter": $branch_filter, "config": $config, "events": $events} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all organizations
#
# GET /admin/orgs
# operationId: adminGetAllOrgs
export def "admin-orgs get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/orgs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List unadopted repositories
#
# GET /admin/unadopted
# operationId: adminUnadoptedList
export def "admin-unadopted list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --pattern: string # pattern of repositories to search for
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pattern" $pattern "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/unadopted" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit, "pattern": $pattern} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete unadopted files
#
# DELETE /admin/unadopted/{owner}/{repo}
# operationId: adminDeleteUnadoptedRepository
export def "admin-unadopted delete-repository" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/admin/unadopted/{owner}/{repo}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Adopt unadopted files as a repository
#
# POST /admin/unadopted/{owner}/{repo}
# operationId: adminAdoptRepository
export def "admin-unadopted create-adopt-repository" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/admin/unadopted/{owner}/{repo}") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# List all users
#
# GET /admin/users
# operationId: adminGetAllUsers
export def "admin-users get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/users" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a user
#
# POST /admin/users
# operationId: adminCreateUser
export def "admin-users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # For explicitly setting the user creation timestamp. Useful when users are migrated from other systems. When omitted, the user's creation timestamp will be set to "now". (format: date-time)
  email: string # format: email
  --full-name: string
  --login-name: string
  --must-change-password: oneof<nothing, bool>
  password: string
  --restricted: oneof<nothing, bool>
  --send-notify: oneof<nothing, bool>
  --source-id: int # format: int64
  username: string
  --visibility: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/users" $auth.query)
  let req_body = {"created_at": $created_at, "email": $email, "full_name": $full_name, "login_name": $login_name, "must_change_password": $must_change_password, "password": $password, "restricted": $restricted, "send_notify": $send_notify, "source_id": $source_id, "username": $username, "visibility": $visibility} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a user
#
# DELETE /admin/users/{username}
# operationId: adminDeleteUser
export def "admin-users delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/admin/users/{username}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Edit an existing user
#
# PATCH /admin/users/{username}
# operationId: adminEditUser
export def "admin-users update-edit" [
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
  --active: oneof<nothing, bool>
  --admin: oneof<nothing, bool>
  --allow-create-organization: oneof<nothing, bool>
  --allow-git-hook: oneof<nothing, bool>
  --allow-import-local: oneof<nothing, bool>
  --description: string
  --email: string # format: email
  --full-name: string
  --location: string
  login_name: string
  --max-repo-creation: int # format: int64
  --must-change-password: oneof<nothing, bool>
  --password: string
  --prohibit-login: oneof<nothing, bool>
  --restricted: oneof<nothing, bool>
  source_id: int # format: int64
  --visibility: string
  --website: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/admin/users/{username}") $auth.query)
  let req_body = {"active": $active, "admin": $admin, "allow_create_organization": $allow_create_organization, "allow_git_hook": $allow_git_hook, "allow_import_local": $allow_import_local, "description": $description, "email": $email, "full_name": $full_name, "location": $location, "login_name": $login_name, "max_repo_creation": $max_repo_creation, "must_change_password": $must_change_password, "password": $password, "prohibit_login": $prohibit_login, "restricted": $restricted, "source_id": $source_id, "visibility": $visibility, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add a public key on behalf of a user
#
# POST /admin/users/{username}/keys
# operationId: adminCreatePublicKey
export def "admin-users-keys create-public" [
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
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/admin/users/{username}/keys") $auth.query)
  let req_body = {"key": $key, "read_only": $read_only, "title": $title} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a user's public key
#
# DELETE /admin/users/{username}/keys/{id}
# operationId: adminDeleteUserPublicKey
export def "admin-users-keys delete-public" [
  username: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/admin/users/{username}/keys/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Create an organization
#
# POST /admin/users/{username}/orgs
# operationId: adminCreateOrg
export def "admin-users-orgs create" [
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
  --description: string
  --full-name: string
  --location: string
  --repo-admin-change-team-access: oneof<nothing, bool>
  --body-username: string
  --visibility: string@visibility-completer # possible values are `public` (default), `limited` or `private`
  --website: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/admin/users/{username}/orgs") $auth.query)
  let req_body = {"description": $description, "full_name": $full_name, "location": $location, "repo_admin_change_team_access": $repo_admin_change_team_access, "username": $body_username, "visibility": $visibility, "website": $website} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Create a repository on behalf of a user
#
# POST /admin/users/{username}/repos
# operationId: adminCreateRepo
export def "admin-users-repos create" [
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
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/admin/users/{username}/repos") $auth.query)
  let req_body = {"auto_init": $auto_init, "default_branch": $default_branch, "description": $description, "gitignores": $gitignores, "issue_labels": $issue_labels, "license": $license, "name": $name, "private": $private, "readme": $readme, "template": $template, "trust_model": $trust_model} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a hook
#
# DELETE /amdin/hooks/{id}
# operationId: adminDeleteHook
export def "amdin-hooks delete-admin" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/amdin/hooks/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Render a markdown document as HTML
#
# POST /markdown
# operationId: renderMarkdown
export def "markdown create-render" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string # Context to render in: body
  --mode: string # Mode to render in: body
  --text: string # Text markdown to render in: body
  --wiki: oneof<nothing, bool> # Is it a wiki page ? in: body
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markdown" $auth.query)
  let req_body = {"Context": $context, "Mode": $mode, "Text": $text, "Wiki": $wiki} | compact
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

# Render raw markdown as HTML
#
# POST /markdown/raw
# operationId: renderMarkdownRaw
export def "markdown-raw create-render" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markdown/raw" $auth.query)
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
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the nodeinfo of the Gitea application
#
# GET /nodeinfo
# operationId: getNodeInfo
export def "nodeinfo get-node" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nodeinfo" $auth.query)
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

# List users's notification threads
#
# GET /notifications
# operationId: notifyGetList
export def "notifications notify-get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # If true, show notifications marked as read. Default value is false
  --status-types: list<string> # Show notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread & pinned.
  --subject-type: list<string> # filter notifications by subject type
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "subject-type" $subject_type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"all": $all, "status-types": $status_types, "subject-type": $subject_type, "since": $since, "before": $before, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Mark notification threads as read, pinned or unread
#
# PUT /notifications
# operationId: notifyReadList
export def "notifications notify-get-list-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-read-at: string # Describes the last point that notifications were checked. Anything updated since this time will not be updated. (format: date-time)
  --all: string # If true, mark all notifications on this repo. Default value is false
  --status-types: list<string> # Mark notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread.
  --to-status: string # Status to mark notifications as, Defaults to read.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_read_at" $last_read_at "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "to-status" $to_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"last_read_at": $last_read_at, "all": $all, "status-types": $status_types, "to-status": $to_status} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [205]
}

# Check if unread notifications exist
#
# GET /notifications/new
# operationId: notifyNewAvailable
export def "notifications-new notify-available" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/new" $auth.query)
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

# Get notification thread by ID
#
# GET /notifications/threads/{id}
# operationId: notifyGetThread
export def "notifications-threads notify-get-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notifications/threads/{id}") $auth.query)
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

# Mark notification thread as read by ID
#
# PATCH /notifications/threads/{id}
# operationId: notifyReadThread
export def "notifications-threads notify-get-by-id-1" [
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
  --to-status: string # Status to mark notifications as (default: read)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "to-status" $to_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notifications/threads/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"to-status": $to_status} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [205]
}

# Create a repository in an organization
#
# POST /org/{org}/repos
# DEPRECATED
# operationId: createOrgRepoDeprecated
@deprecated
export def "org-repos create-deprecated" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/org/{org}/repos") $auth.query)
  let req_body = {"auto_init": $auto_init, "default_branch": $default_branch, "description": $description, "gitignores": $gitignores, "issue_labels": $issue_labels, "license": $license, "name": $name, "private": $private, "readme": $readme, "template": $template, "trust_model": $trust_model} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get list of organizations
#
# GET /orgs
# operationId: orgGetAll
export def "orgs get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an organization
#
# POST /orgs
# operationId: orgCreate
export def "orgs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --full-name: string
  --location: string
  --repo-admin-change-team-access: oneof<nothing, bool>
  username: string
  --visibility: string@visibility-completer # possible values are `public` (default), `limited` or `private`
  --website: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgs" $auth.query)
  let req_body = {"description": $description, "full_name": $full_name, "location": $location, "repo_admin_change_team_access": $repo_admin_change_team_access, "username": $username, "visibility": $visibility, "website": $website} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an organization
#
# DELETE /orgs/{org}
# operationId: orgDelete
export def "orgs delete" [
  org: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an organization
#
# GET /orgs/{org}
# operationId: orgGet
export def "orgs get" [
  org: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}") $auth.query)
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

# Edit an organization
#
# PATCH /orgs/{org}
# operationId: orgEdit
export def "orgs update-edit" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --full-name: string
  --location: string
  --repo-admin-change-team-access: oneof<nothing, bool>
  --visibility: string@visibility-completer # possible values are `public`, `limited` or `private`
  --website: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}") $auth.query)
  let req_body = {"description": $description, "full_name": $full_name, "location": $location, "repo_admin_change_team_access": $repo_admin_change_team_access, "visibility": $visibility, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List an organization's webhooks
#
# GET /orgs/{org}/hooks
# operationId: orgListHooks
export def "orgs-hooks list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/hooks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a hook
#
# POST /orgs/{org}/hooks
# operationId: orgCreateHook
export def "orgs-hooks create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string
  --branch-filter: string
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list<string>
  type: string@type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/hooks") $auth.query)
  let req_body = {"active": $active, "authorization_header": $authorization_header, "branch_filter": $branch_filter, "config": $config, "events": $events, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a hook
#
# DELETE /orgs/{org}/hooks/{id}
# operationId: orgDeleteHook
export def "orgs-hooks delete" [
  org: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), id: (encode-path-segment $id)} | format pattern "/orgs/{org}/hooks/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a hook
#
# GET /orgs/{org}/hooks/{id}
# operationId: orgGetHook
export def "orgs-hooks get" [
  org: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), id: (encode-path-segment $id)} | format pattern "/orgs/{org}/hooks/{id}") $auth.query)
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

# Update a hook
#
# PATCH /orgs/{org}/hooks/{id}
# operationId: orgEditHook
export def "orgs-hooks update-edit" [
  org: string
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
  --active: oneof<nothing, bool>
  --authorization-header: string
  --branch-filter: string
  --config: record
  --events: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), id: (encode-path-segment $id)} | format pattern "/orgs/{org}/hooks/{id}") $auth.query)
  let req_body = {"active": $active, "authorization_header": $authorization_header, "branch_filter": $branch_filter, "config": $config, "events": $events} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List an organization's labels
#
# GET /orgs/{org}/labels
# operationId: orgListLabels
export def "orgs-labels list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/labels") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a label for an organization
#
# POST /orgs/{org}/labels
# operationId: orgCreateLabel
export def "orgs-labels create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/labels") $auth.query)
  let req_body = {"color": $color, "description": $description, "exclusive": $exclusive, "name": $name} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a label
#
# DELETE /orgs/{org}/labels/{id}
# operationId: orgDeleteLabel
export def "orgs-labels delete" [
  org: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), id: (encode-path-segment $id)} | format pattern "/orgs/{org}/labels/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a single label
#
# GET /orgs/{org}/labels/{id}
# operationId: orgGetLabel
export def "orgs-labels get" [
  org: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), id: (encode-path-segment $id)} | format pattern "/orgs/{org}/labels/{id}") $auth.query)
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

# Update a label
#
# PATCH /orgs/{org}/labels/{id}
# operationId: orgEditLabel
export def "orgs-labels update-edit" [
  org: string
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
  --color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), id: (encode-path-segment $id)} | format pattern "/orgs/{org}/labels/{id}") $auth.query)
  let req_body = {"color": $color, "description": $description, "exclusive": $exclusive, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List an organization's members
#
# GET /orgs/{org}/members
# operationId: orgListMembers
export def "orgs-members list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/members") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove a member from an organization
#
# DELETE /orgs/{org}/members/{username}
# operationId: orgDeleteMember
export def "orgs-members delete" [
  org: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), username: (encode-path-segment $username)} | format pattern "/orgs/{org}/members/{username}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Check if a user is a member of an organization
#
# GET /orgs/{org}/members/{username}
# operationId: orgIsMember
export def "orgs-members get-is" [
  org: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), username: (encode-path-segment $username)} | format pattern "/orgs/{org}/members/{username}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204 303]
}

# List an organization's public members
#
# GET /orgs/{org}/public_members
# operationId: orgListPublicMembers
export def "orgs-public-members list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/public_members") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Conceal a user's membership
#
# DELETE /orgs/{org}/public_members/{username}
# operationId: orgConcealMember
export def "orgs-public-members delete-conceal" [
  org: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), username: (encode-path-segment $username)} | format pattern "/orgs/{org}/public_members/{username}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Check if a user is a public member of an organization
#
# GET /orgs/{org}/public_members/{username}
# operationId: orgIsPublicMember
export def "orgs-public-members get-is" [
  org: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), username: (encode-path-segment $username)} | format pattern "/orgs/{org}/public_members/{username}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Publicize a user's membership
#
# PUT /orgs/{org}/public_members/{username}
# operationId: orgPublicizeMember
export def "orgs-public-members update-publicize" [
  org: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org), username: (encode-path-segment $username)} | format pattern "/orgs/{org}/public_members/{username}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# List an organization's repos
#
# GET /orgs/{org}/repos
# operationId: orgListRepos
export def "orgs-repos list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/repos") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a repository in an organization
#
# POST /orgs/{org}/repos
# operationId: createOrgRepo
export def "orgs-repos create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/repos") $auth.query)
  let req_body = {"auto_init": $auto_init, "default_branch": $default_branch, "description": $description, "gitignores": $gitignores, "issue_labels": $issue_labels, "license": $license, "name": $name, "private": $private, "readme": $readme, "template": $template, "trust_model": $trust_model} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List an organization's teams
#
# GET /orgs/{org}/teams
# operationId: orgListTeams
export def "orgs-teams list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/teams") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a team
#
# POST /orgs/{org}/teams
# operationId: orgCreateTeam
export def "orgs-teams create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --can-create-org-repo: oneof<nothing, bool>
  --description: string
  --includes-all-repositories: oneof<nothing, bool>
  name: string
  --permission: string@permission-completer
  --units: list<string> # e.g. [repo.code, repo.issues, repo.ext_issues, repo.wiki, repo.pulls, repo.releases, repo.projects, repo.ext_wiki]
  --units-map: record # e.g. {repo.code: read, repo.ext_issues: none, repo.ext_wiki: none, repo.issues: write, repo.projects: none, repo.pulls: owner, repo.releases: none, repo.wiki: admin}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/teams") $auth.query)
  let req_body = {"can_create_org_repo": $can_create_org_repo, "description": $description, "includes_all_repositories": $includes_all_repositories, "name": $name, "permission": $permission, "units": $units, "units_map": $units_map} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Search for teams within an organization
#
# GET /orgs/{org}/teams/search
# operationId: teamSearch
export def "orgs-teams-search list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # keywords to search
  --include-desc: oneof<nothing, bool> # include search within team description (defaults to true)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> record<data: table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "include_desc" $include_desc "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org: (encode-path-segment $org)} | format pattern "/orgs/{org}/teams/search") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "include_desc": $include_desc, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all packages of an owner
#
# GET /packages/{owner}
# operationId: listPackages
export def "packages list" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --type: string@type-completer-1 # package type filter
  --q: string # name filter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner)} | format pattern "/packages/{owner}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit, "type": $type, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a package
#
# DELETE /packages/{owner}/{type}/{name}/{version}
# operationId: deletePackage
export def "packages delete" [
  owner: string
  type: string
  name: string
  version: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), type: (encode-path-segment $type), name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/packages/{owner}/{type}/{name}/{version}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets a package
#
# GET /packages/{owner}/{type}/{name}/{version}
# operationId: getPackage
export def "packages get" [
  owner: string
  type: string
  name: string
  version: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), type: (encode-path-segment $type), name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/packages/{owner}/{type}/{name}/{version}") $auth.query)
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

# Gets all files of a package
#
# GET /packages/{owner}/{type}/{name}/{version}/files
# operationId: listPackageFiles
export def "packages-files list" [
  owner: string
  type: string
  name: string
  version: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), type: (encode-path-segment $type), name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/packages/{owner}/{type}/{name}/{version}/files") $auth.query)
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

# Search for issues across the repositories that the user has access to
#
# GET /repos/issues/search
# operationId: issueSearchIssues
export def "repos-issues-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # whether issue is open or closed
  --labels: string # comma separated list of labels. Fetch only issues that have any of this labels. Non existent labels are discarded
  --milestones: string # comma separated list of milestone names. Fetch only issues that have any of this milestones. Non existent are discarded
  --q: string # search string
  --priority-repo-id: int # repository to prioritize in the results (format: int64)
  --type: string # filter by type (issues / pulls) if set
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --assigned: oneof<nothing, bool> # filter (issues / pulls) assigned to you, default is false
  --created: oneof<nothing, bool> # filter (issues / pulls) created by you, default is false
  --mentioned: oneof<nothing, bool> # filter (issues / pulls) mentioning you, default is false
  --review-requested: oneof<nothing, bool> # filter pulls requesting your review, default is false
  --reviewed: oneof<nothing, bool> # filter pulls reviewed by you, default is false
  --owner: string # filter by owner
  --team: string # filter by team (requires organization owner parameter to be provided)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "milestones" $milestones "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "priority_repo_id" $priority_repo_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "assigned" $assigned "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "mentioned" $mentioned "scalar") (serialize-qp "review_requested" $review_requested "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repos/issues/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state, "labels": $labels, "milestones": $milestones, "q": $q, "priority_repo_id": $priority_repo_id, "type": $type, "since": $since, "before": $before, "assigned": $assigned, "created": $created, "mentioned": $mentioned, "review_requested": $review_requested, "reviewed": $reviewed, "owner": $owner, "team": $team, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Migrate a remote git repository
#
# POST /repos/migrate
# operationId: repoMigrate
export def "repos-migrate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-password: string
  --auth-token: string
  --auth-username: string
  clone_addr: string
  --description: string
  --issues: oneof<nothing, bool>
  --labels: oneof<nothing, bool>
  --lfs: oneof<nothing, bool>
  --lfs-endpoint: string
  --milestones: oneof<nothing, bool>
  --mirror: oneof<nothing, bool>
  --mirror-interval: string
  --private: oneof<nothing, bool>
  --pull-requests: oneof<nothing, bool>
  --releases: oneof<nothing, bool>
  repo_name: string
  --repo-owner: string # Name of User or Organisation who will own Repo after migration
  --service: string@service-completer
  --uid: int # deprecated (only for backwards compatibility) (format: int64)
  --wiki: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/repos/migrate" $auth.query)
  let req_body = {"auth_password": $auth_password, "auth_token": $auth_token, "auth_username": $auth_username, "clone_addr": $clone_addr, "description": $description, "issues": $issues, "labels": $labels, "lfs": $lfs, "lfs_endpoint": $lfs_endpoint, "milestones": $milestones, "mirror": $mirror, "mirror_interval": $mirror_interval, "private": $private, "pull_requests": $pull_requests, "releases": $releases, "repo_name": $repo_name, "repo_owner": $repo_owner, "service": $service, "uid": $uid, "wiki": $wiki} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Search for repositories
#
# GET /repos/search
# operationId: repoSearch
export def "repos-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # keyword
  --topic: oneof<nothing, bool> # Limit search to repositories with keyword as topic
  --include-desc: oneof<nothing, bool> # include search of keyword within repository description
  --uid: int # search only for repos that the user with the given id owns or contributes to (format: int64)
  --priority-owner-id: int # repo owner to prioritize in the results (format: int64)
  --team-id: int # search only for repos that belong to the given team id (format: int64)
  --starred-by: int # search only for repos that the user with the given id has starred (format: int64)
  --private: oneof<nothing, bool> # include private repositories this user has access to (defaults to true)
  --is-private: oneof<nothing, bool> # show only pubic, private or all repositories (defaults to all)
  --template: oneof<nothing, bool> # include template repositories this user has access to (defaults to true)
  --archived: oneof<nothing, bool> # show only archived, non-archived or all repositories (defaults to all)
  --mode: string # type of repository to search for. Supported values are "fork", "source", "mirror" and "collaborative"
  --exclusive: oneof<nothing, bool> # if `uid` is given, search only for repos that the user owns
  --qp-sort: string # sort repos by attribute. Supported values are "alpha", "created", "updated", "size", and "id". Default is "alpha"
  --order: string # sort order, either "asc" (ascending) or "desc" (descending). Default is "asc", ignored if "sort" is not specified.
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "topic" $topic "scalar") (serialize-qp "includeDesc" $include_desc "scalar") (serialize-qp "uid" $uid "scalar") (serialize-qp "priority_owner_id" $priority_owner_id "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "starredBy" $starred_by "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "is_private" $is_private "scalar") (serialize-qp "template" $template "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "exclusive" $exclusive "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repos/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "topic": $topic, "includeDesc": $include_desc, "uid": $uid, "priority_owner_id": $priority_owner_id, "team_id": $team_id, "starredBy": $starred_by, "private": $private, "is_private": $is_private, "template": $template, "archived": $archived, "mode": $mode, "exclusive": $exclusive, "sort": $qp_sort, "order": $order, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a repository
#
# DELETE /repos/{owner}/{repo}
# operationId: repoDelete
export def "repos delete" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a repository
#
# GET /repos/{owner}/{repo}
# operationId: repoGet
export def "repos get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}") $auth.query)
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

# Edit a repository's properties. Only fields that are set will be changed.
#
# PATCH /repos/{owner}/{repo}
# operationId: repoEdit
# --external_tracker shape: {external_tracker_format?: string, external_tracker_regexp_pattern?: string, external_tracker_style?: string, external_tracker_url?: string}
# --external_wiki shape: {external_wiki_url?: string}
# --internal_tracker shape: {allow_only_contributors_to_track_time?: bool, enable_issue_dependencies?: bool, enable_time_tracker?: bool}
export def "repos update-edit" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-manual-merge: oneof<nothing, bool> # either `true` to allow mark pr as merged manually, or `false` to prevent it.
  --allow-merge-commits: oneof<nothing, bool> # either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging pull requests with merge commits.
  --allow-rebase: oneof<nothing, bool> # either `true` to allow rebase-merging pull requests, or `false` to prevent rebase-merging.
  --allow-rebase-explicit: oneof<nothing, bool> # either `true` to allow rebase with explicit merge commits (--no-ff), or `false` to prevent rebase with explicit merge commits.
  --allow-rebase-update: oneof<nothing, bool> # either `true` to allow updating pull request branch by rebase, or `false` to prevent it.
  --allow-squash-merge: oneof<nothing, bool> # either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging.
  --archived: oneof<nothing, bool> # set to `true` to archive this repository.
  --autodetect-manual-merge: oneof<nothing, bool> # either `true` to enable AutodetectManualMerge, or `false` to prevent it. Note: In some special cases, misjudgments can occur.
  --default-allow-maintainer-edit: oneof<nothing, bool> # set to `true` to allow edits from maintainers by default
  --default-branch: string # sets the default branch for this repository.
  --default-delete-branch-after-merge: oneof<nothing, bool> # set to `true` to delete pr branch after merge by default
  --default-merge-style: string # set to a merge style to be used by this repository: "merge", "rebase", "rebase-merge", or "squash".
  --description: string # a short description of the repository.
  --enable-prune: oneof<nothing, bool> # enable prune - remove obsolete remote-tracking references
  --external-tracker: record # ExternalTracker represents settings for external tracker — shape: {external_tracker_format?: string, external_tracker_regexp_pattern?: string, external_tracker_style?: string, external_tracker_url?: string}
  --external-wiki: record # ExternalWiki represents setting for external wiki — shape: {external_wiki_url?: string}
  --has-issues: oneof<nothing, bool> # either `true` to enable issues for this repository or `false` to disable them.
  --has-projects: oneof<nothing, bool> # either `true` to enable project unit, or `false` to disable them.
  --has-pull-requests: oneof<nothing, bool> # either `true` to allow pull requests, or `false` to prevent pull request.
  --has-wiki: oneof<nothing, bool> # either `true` to enable the wiki for this repository or `false` to disable it.
  --ignore-whitespace-conflicts: oneof<nothing, bool> # either `true` to ignore whitespace for conflicts, or `false` to not ignore whitespace.
  --internal-tracker: record # InternalTracker represents settings for internal tracker — shape: {allow_only_contributors_to_track_time?: bool, enable_issue_dependencies?: bool, enable_time_tracker?: bool}
  --mirror-interval: string # set to a string like `8h30m0s` to set the mirror interval time
  --name: string # name of the repository
  --private: oneof<nothing, bool> # either `true` to make the repository private or `false` to make it public. Note: you will get a 422 error if the organization restricts changing repository visibility to organization owners and a non-owner tries to change the value of private.
  --template: oneof<nothing, bool> # either `true` to make this repository a template or `false` to make it a normal repository
  --website: string # a URL with more information about the repository.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}") $auth.query)
  let req_body = {"allow_manual_merge": $allow_manual_merge, "allow_merge_commits": $allow_merge_commits, "allow_rebase": $allow_rebase, "allow_rebase_explicit": $allow_rebase_explicit, "allow_rebase_update": $allow_rebase_update, "allow_squash_merge": $allow_squash_merge, "archived": $archived, "autodetect_manual_merge": $autodetect_manual_merge, "default_allow_maintainer_edit": $default_allow_maintainer_edit, "default_branch": $default_branch, "default_delete_branch_after_merge": $default_delete_branch_after_merge, "default_merge_style": $default_merge_style, "description": $description, "enable_prune": $enable_prune, "external_tracker": $external_tracker, "external_wiki": $external_wiki, "has_issues": $has_issues, "has_projects": $has_projects, "has_pull_requests": $has_pull_requests, "has_wiki": $has_wiki, "ignore_whitespace_conflicts": $ignore_whitespace_conflicts, "internal_tracker": $internal_tracker, "mirror_interval": $mirror_interval, "name": $name, "private": $private, "template": $template, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get an archive of a repository
#
# GET /repos/{owner}/{repo}/archive/{archive}
# operationId: repoGetArchive
export def "repos-archive get" [
  owner: string
  repo: string
  archive: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($archive | is-empty) { error make --unspanned { msg: "path parameter 'archive' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), archive: (encode-path-segment $archive)} | format pattern "/repos/{owner}/{repo}/archive/{archive}") $auth.query)
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

# Return all users that have write access and can be assigned to issues
#
# GET /repos/{owner}/{repo}/assignees
# operationId: repoGetAssignees
export def "repos-assignees get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/assignees") $auth.query)
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

# List branch protections for a repository
#
# GET /repos/{owner}/{repo}/branch_protections
# operationId: repoListBranchProtection
export def "repos-branch-protections list" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/branch_protections") $auth.query)
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

# Create a branch protections for a repository
#
# POST /repos/{owner}/{repo}/branch_protections
# operationId: repoCreateBranchProtection
export def "repos-branch-protections create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --approvals-whitelist-teams: list<string>
  --approvals-whitelist-username: list<string>
  --block-on-official-review-requests: oneof<nothing, bool>
  --block-on-outdated-branch: oneof<nothing, bool>
  --block-on-rejected-reviews: oneof<nothing, bool>
  --branch-name: string # Deprecated: true
  --dismiss-stale-approvals: oneof<nothing, bool>
  --enable-approvals-whitelist: oneof<nothing, bool>
  --enable-merge-whitelist: oneof<nothing, bool>
  --enable-push: oneof<nothing, bool>
  --enable-push-whitelist: oneof<nothing, bool>
  --enable-status-check: oneof<nothing, bool>
  --merge-whitelist-teams: list<string>
  --merge-whitelist-usernames: list<string>
  --protected-file-patterns: string
  --push-whitelist-deploy-keys: oneof<nothing, bool>
  --push-whitelist-teams: list<string>
  --push-whitelist-usernames: list<string>
  --require-signed-commits: oneof<nothing, bool>
  --required-approvals: int # format: int64
  --rule-name: string
  --status-check-contexts: list<string>
  --unprotected-file-patterns: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/branch_protections") $auth.query)
  let req_body = {"approvals_whitelist_teams": $approvals_whitelist_teams, "approvals_whitelist_username": $approvals_whitelist_username, "block_on_official_review_requests": $block_on_official_review_requests, "block_on_outdated_branch": $block_on_outdated_branch, "block_on_rejected_reviews": $block_on_rejected_reviews, "branch_name": $branch_name, "dismiss_stale_approvals": $dismiss_stale_approvals, "enable_approvals_whitelist": $enable_approvals_whitelist, "enable_merge_whitelist": $enable_merge_whitelist, "enable_push": $enable_push, "enable_push_whitelist": $enable_push_whitelist, "enable_status_check": $enable_status_check, "merge_whitelist_teams": $merge_whitelist_teams, "merge_whitelist_usernames": $merge_whitelist_usernames, "protected_file_patterns": $protected_file_patterns, "push_whitelist_deploy_keys": $push_whitelist_deploy_keys, "push_whitelist_teams": $push_whitelist_teams, "push_whitelist_usernames": $push_whitelist_usernames, "require_signed_commits": $require_signed_commits, "required_approvals": $required_approvals, "rule_name": $rule_name, "status_check_contexts": $status_check_contexts, "unprotected_file_patterns": $unprotected_file_patterns} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a specific branch protection for the repository
#
# DELETE /repos/{owner}/{repo}/branch_protections/{name}
# operationId: repoDeleteBranchProtection
export def "repos-branch-protections delete" [
  owner: string
  repo: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), name: (encode-path-segment $name)} | format pattern "/repos/{owner}/{repo}/branch_protections/{name}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a specific branch protection for the repository
#
# GET /repos/{owner}/{repo}/branch_protections/{name}
# operationId: repoGetBranchProtection
export def "repos-branch-protections get" [
  owner: string
  repo: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), name: (encode-path-segment $name)} | format pattern "/repos/{owner}/{repo}/branch_protections/{name}") $auth.query)
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

# Edit a branch protections for a repository. Only fields that are set will be changed
#
# PATCH /repos/{owner}/{repo}/branch_protections/{name}
# operationId: repoEditBranchProtection
export def "repos-branch-protections update-edit" [
  owner: string
  repo: string
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
  --approvals-whitelist-teams: list<string>
  --approvals-whitelist-username: list<string>
  --block-on-official-review-requests: oneof<nothing, bool>
  --block-on-outdated-branch: oneof<nothing, bool>
  --block-on-rejected-reviews: oneof<nothing, bool>
  --dismiss-stale-approvals: oneof<nothing, bool>
  --enable-approvals-whitelist: oneof<nothing, bool>
  --enable-merge-whitelist: oneof<nothing, bool>
  --enable-push: oneof<nothing, bool>
  --enable-push-whitelist: oneof<nothing, bool>
  --enable-status-check: oneof<nothing, bool>
  --merge-whitelist-teams: list<string>
  --merge-whitelist-usernames: list<string>
  --protected-file-patterns: string
  --push-whitelist-deploy-keys: oneof<nothing, bool>
  --push-whitelist-teams: list<string>
  --push-whitelist-usernames: list<string>
  --require-signed-commits: oneof<nothing, bool>
  --required-approvals: int # format: int64
  --status-check-contexts: list<string>
  --unprotected-file-patterns: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), name: (encode-path-segment $name)} | format pattern "/repos/{owner}/{repo}/branch_protections/{name}") $auth.query)
  let req_body = {"approvals_whitelist_teams": $approvals_whitelist_teams, "approvals_whitelist_username": $approvals_whitelist_username, "block_on_official_review_requests": $block_on_official_review_requests, "block_on_outdated_branch": $block_on_outdated_branch, "block_on_rejected_reviews": $block_on_rejected_reviews, "dismiss_stale_approvals": $dismiss_stale_approvals, "enable_approvals_whitelist": $enable_approvals_whitelist, "enable_merge_whitelist": $enable_merge_whitelist, "enable_push": $enable_push, "enable_push_whitelist": $enable_push_whitelist, "enable_status_check": $enable_status_check, "merge_whitelist_teams": $merge_whitelist_teams, "merge_whitelist_usernames": $merge_whitelist_usernames, "protected_file_patterns": $protected_file_patterns, "push_whitelist_deploy_keys": $push_whitelist_deploy_keys, "push_whitelist_teams": $push_whitelist_teams, "push_whitelist_usernames": $push_whitelist_usernames, "require_signed_commits": $require_signed_commits, "required_approvals": $required_approvals, "status_check_contexts": $status_check_contexts, "unprotected_file_patterns": $unprotected_file_patterns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List a repository's branches
#
# GET /repos/{owner}/{repo}/branches
# operationId: repoListBranches
export def "repos-branches list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/branches") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a branch
#
# POST /repos/{owner}/{repo}/branches
# operationId: repoCreateBranch
export def "repos-branches create-branch" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_branch_name: string # Name of the branch to create
  --old-branch-name: string # Name of the old branch to create from
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/branches") $auth.query)
  let req_body = {"new_branch_name": $new_branch_name, "old_branch_name": $old_branch_name} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a specific branch from a repository
#
# DELETE /repos/{owner}/{repo}/branches/{branch}
# operationId: repoDeleteBranch
export def "repos-branches delete" [
  owner: string
  repo: string
  branch: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), branch: (encode-path-segment $branch)} | format pattern "/repos/{owner}/{repo}/branches/{branch}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve a specific branch from a repository, including its effective branch protection
#
# GET /repos/{owner}/{repo}/branches/{branch}
# operationId: repoGetBranch
export def "repos-branches get" [
  owner: string
  repo: string
  branch: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), branch: (encode-path-segment $branch)} | format pattern "/repos/{owner}/{repo}/branches/{branch}") $auth.query)
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

# List a repository's collaborators
#
# GET /repos/{owner}/{repo}/collaborators
# operationId: repoListCollaborators
export def "repos-collaborators list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/collaborators") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a collaborator from a repository
#
# DELETE /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoDeleteCollaborator
export def "repos-collaborators delete" [
  owner: string
  repo: string
  collaborator: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), collaborator: (encode-path-segment $collaborator)} | format pattern "/repos/{owner}/{repo}/collaborators/{collaborator}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Check if a user is a collaborator of a repository
#
# GET /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoCheckCollaborator
export def "repos-collaborators check" [
  owner: string
  repo: string
  collaborator: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), collaborator: (encode-path-segment $collaborator)} | format pattern "/repos/{owner}/{repo}/collaborators/{collaborator}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Add a collaborator to a repository
#
# PUT /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoAddCollaborator
export def "repos-collaborators create" [
  owner: string
  repo: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), collaborator: (encode-path-segment $collaborator)} | format pattern "/repos/{owner}/{repo}/collaborators/{collaborator}") $auth.query)
  let req_body = {"permission": $permission} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get repository permissions for a user
#
# GET /repos/{owner}/{repo}/collaborators/{collaborator}/permission
# operationId: repoGetRepoPermissions
export def "repos-collaborators-permission get" [
  owner: string
  repo: string
  collaborator: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($collaborator | is-empty) { error make --unspanned { msg: "path parameter 'collaborator' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), collaborator: (encode-path-segment $collaborator)} | format pattern "/repos/{owner}/{repo}/collaborators/{collaborator}/permission") $auth.query)
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

# Get a list of all commits from a repository
#
# GET /repos/{owner}/{repo}/commits
# operationId: repoGetAllCommits
export def "repos-commits get-list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sha: string # SHA or branch to start listing commits from (usually 'master')
  --path: string # filepath of a file/dir
  --stat: oneof<nothing, bool> # include diff stats for every commit (disable for speedup, default 'true')
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results (ignored if used with 'path')
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "sha" $sha "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "stat" $stat "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/commits") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sha": $sha, "path": $path, "stat": $stat, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a commit's combined status, by branch/tag/commit reference
#
# GET /repos/{owner}/{repo}/commits/{ref}/status
# operationId: repoGetCombinedStatusByRef
export def "repos-commits-status get-combined" [
  owner: string
  repo: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($ref | is-empty) { error make --unspanned { msg: "path parameter 'ref' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), ref: (encode-path-segment $ref)} | format pattern "/repos/{owner}/{repo}/commits/{ref}/status") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a commit's statuses, by branch/tag/commit reference
#
# GET /repos/{owner}/{repo}/commits/{ref}/statuses
# operationId: repoListStatusesByRef
export def "repos-commits-statuses list" [
  owner: string
  repo: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer # type of sort
  --state: string@state-completer # type of state
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($ref | is-empty) { error make --unspanned { msg: "path parameter 'ref' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), ref: (encode-path-segment $ref)} | format pattern "/repos/{owner}/{repo}/commits/{ref}/statuses") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort": $qp_sort, "state": $state, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the metadata of all the entries of the root dir
#
# GET /repos/{owner}/{repo}/contents
# operationId: repoGetContentsList
export def "repos-contents get-list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/contents") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ref": $ref} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a file in a repository
#
# DELETE /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoDeleteFile
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-contents delete-file" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  sha: string # sha is the SHA for the file that already exists
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($filepath | is-empty) { error make --unspanned { msg: "path parameter 'filepath' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), filepath: (encode-path-segment $filepath)} | format pattern "/repos/{owner}/{repo}/contents/{filepath}") $auth.query)
  let req_body = {"author": $author, "branch": $branch, "committer": $committer, "dates": $dates, "message": $message, "new_branch": $new_branch, "sha": $sha, "signoff": $signoff} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets the metadata and contents (if a file) of an entry in a repository, or a list of entries if a dir
#
# GET /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoGetContents
export def "repos-contents get" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($filepath | is-empty) { error make --unspanned { msg: "path parameter 'filepath' must be non-empty" } }
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), filepath: (encode-path-segment $filepath)} | format pattern "/repos/{owner}/{repo}/contents/{filepath}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ref": $ref} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a file in a repository
#
# POST /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoCreateFile
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-contents create-file" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($filepath | is-empty) { error make --unspanned { msg: "path parameter 'filepath' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), filepath: (encode-path-segment $filepath)} | format pattern "/repos/{owner}/{repo}/contents/{filepath}") $auth.query)
  let req_body = {"author": $author, "branch": $branch, "committer": $committer, "content": $content, "dates": $dates, "message": $message, "new_branch": $new_branch, "signoff": $signoff} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Update a file in a repository
#
# PUT /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoUpdateFile
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-contents update-file" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --from-path: string # from_path (optional) is the path of the original file which will be moved/renamed to the path in the URL
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  sha: string # sha is the SHA for the file that already exists
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($filepath | is-empty) { error make --unspanned { msg: "path parameter 'filepath' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), filepath: (encode-path-segment $filepath)} | format pattern "/repos/{owner}/{repo}/contents/{filepath}") $auth.query)
  let req_body = {"author": $author, "branch": $branch, "committer": $committer, "content": $content, "dates": $dates, "from_path": $from_path, "message": $message, "new_branch": $new_branch, "sha": $sha, "signoff": $signoff} | compact
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

# Apply diff patch to repository
#
# POST /repos/{owner}/{repo}/diffpatch
# operationId: repoApplyDiffPatch
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-diffpatch update-apply-diff" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) to base this file from. if not given, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --from-path: string # from_path (optional) is the path of the original file which will be moved/renamed to the path in the URL
  --message: string # message (optional) for the commit of this file. if not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from `branch` before creating the file
  sha: string # sha is the SHA for the file that already exists
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/diffpatch") $auth.query)
  let req_body = {"author": $author, "branch": $branch, "committer": $committer, "content": $content, "dates": $dates, "from_path": $from_path, "message": $message, "new_branch": $new_branch, "sha": $sha, "signoff": $signoff} | compact
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

# Get the EditorConfig definitions of a file in a repository
#
# GET /repos/{owner}/{repo}/editorconfig/{filepath}
# operationId: repoGetEditorConfig
export def "repos-editorconfig get-editor-config" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($filepath | is-empty) { error make --unspanned { msg: "path parameter 'filepath' must be non-empty" } }
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), filepath: (encode-path-segment $filepath)} | format pattern "/repos/{owner}/{repo}/editorconfig/{filepath}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ref": $ref} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List a repository's forks
#
# GET /repos/{owner}/{repo}/forks
# operationId: listForks
export def "repos-forks list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/forks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fork a repository
#
# POST /repos/{owner}/{repo}/forks
# operationId: createFork
export def "repos-forks create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # name of the forked repository
  --organization: string # organization name, if forking into an organization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/forks") $auth.query)
  let req_body = {"name": $name, "organization": $organization} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets the blob of a repository.
#
# GET /repos/{owner}/{repo}/git/blobs/{sha}
# operationId: GetBlob
export def "repos-git-blobs get" [
  owner: string
  repo: string
  sha: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha)} | format pattern "/repos/{owner}/{repo}/git/blobs/{sha}") $auth.query)
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

# Get a single commit from a repository
#
# GET /repos/{owner}/{repo}/git/commits/{sha}
# operationId: repoGetSingleCommit
export def "repos-git-commits get-single" [
  owner: string
  repo: string
  sha: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha)} | format pattern "/repos/{owner}/{repo}/git/commits/{sha}") $auth.query)
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

# Get a commit's diff or patch
#
# GET /repos/{owner}/{repo}/git/commits/{sha}.{diffType}
# operationId: repoDownloadCommitDiffOrPatch
export def "repos-git-commits download-diff-or-update" [
  owner: string
  repo: string
  sha: string
  diff_type: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  if ($diff_type | is-empty) { error make --unspanned { msg: "path parameter 'diffType' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha), diff_type: (encode-path-segment $diff_type)} | format pattern "/repos/{owner}/{repo}/git/commits/{sha}.{diff_type}") $auth.query)
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

# Get a note corresponding to a single commit from a repository
#
# GET /repos/{owner}/{repo}/git/notes/{sha}
# operationId: repoGetNote
export def "repos-git-notes get" [
  owner: string
  repo: string
  sha: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha)} | format pattern "/repos/{owner}/{repo}/git/notes/{sha}") $auth.query)
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

# Get specified ref or filtered repository's refs
#
# GET /repos/{owner}/{repo}/git/refs
# operationId: repoListAllGitRefs
export def "repos-git-refs list" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/git/refs") $auth.query)
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

# Get specified ref or filtered repository's refs
#
# GET /repos/{owner}/{repo}/git/refs/{ref}
# operationId: repoListGitRefs
export def "repos-git-refs list-1" [
  owner: string
  repo: string
  ref: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($ref | is-empty) { error make --unspanned { msg: "path parameter 'ref' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), ref: (encode-path-segment $ref)} | format pattern "/repos/{owner}/{repo}/git/refs/{ref}") $auth.query)
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

# Gets the tag object of an annotated tag (not lightweight tags)
#
# GET /repos/{owner}/{repo}/git/tags/{sha}
# operationId: GetAnnotatedTag
export def "repos-git-tags get-annotated" [
  owner: string
  repo: string
  sha: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha)} | format pattern "/repos/{owner}/{repo}/git/tags/{sha}") $auth.query)
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

# Gets the tree of a repository.
#
# GET /repos/{owner}/{repo}/git/trees/{sha}
# operationId: GetTree
export def "repos-git-trees get" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # show all directories and files
  --page: int # page number; the 'truncated' field in the response will be true if there are still more items after this page, false if the last page
  --per-page: int # number of items per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  let qp = [(serialize-qp "recursive" $recursive "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha)} | format pattern "/repos/{owner}/{repo}/git/trees/{sha}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"recursive": $recursive, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the hooks in a repository
#
# GET /repos/{owner}/{repo}/hooks
# operationId: repoListHooks
export def "repos-hooks list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/hooks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a hook
#
# POST /repos/{owner}/{repo}/hooks
# operationId: repoCreateHook
export def "repos-hooks create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string
  --branch-filter: string
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list<string>
  type: string@type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/hooks") $auth.query)
  let req_body = {"active": $active, "authorization_header": $authorization_header, "branch_filter": $branch_filter, "config": $config, "events": $events, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List the Git hooks in a repository
#
# GET /repos/{owner}/{repo}/hooks/git
# operationId: repoListGitHooks
export def "repos-hooks-git list" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/hooks/git") $auth.query)
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

# Delete a Git hook in a repository
#
# DELETE /repos/{owner}/{repo}/hooks/git/{id}
# operationId: repoDeleteGitHook
export def "repos-hooks-git delete" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/hooks/git/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a Git hook
#
# GET /repos/{owner}/{repo}/hooks/git/{id}
# operationId: repoGetGitHook
export def "repos-hooks-git get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/hooks/git/{id}") $auth.query)
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

# Edit a Git hook in a repository
#
# PATCH /repos/{owner}/{repo}/hooks/git/{id}
# operationId: repoEditGitHook
export def "repos-hooks-git update-edit" [
  owner: string
  repo: string
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
  --content: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/hooks/git/{id}") $auth.query)
  let req_body = {"content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a hook in a repository
#
# DELETE /repos/{owner}/{repo}/hooks/{id}
# operationId: repoDeleteHook
export def "repos-hooks delete" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/hooks/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a hook
#
# GET /repos/{owner}/{repo}/hooks/{id}
# operationId: repoGetHook
export def "repos-hooks get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/hooks/{id}") $auth.query)
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

# Edit a hook in a repository
#
# PATCH /repos/{owner}/{repo}/hooks/{id}
# operationId: repoEditHook
export def "repos-hooks update-edit" [
  owner: string
  repo: string
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
  --active: oneof<nothing, bool>
  --authorization-header: string
  --branch-filter: string
  --config: record
  --events: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/hooks/{id}") $auth.query)
  let req_body = {"active": $active, "authorization_header": $authorization_header, "branch_filter": $branch_filter, "config": $config, "events": $events} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Test a push webhook
#
# POST /repos/{owner}/{repo}/hooks/{id}/tests
# operationId: repoTestHook
export def "repos-hooks-tests test" [
  owner: string
  repo: string
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
  --ref: string # The name of the commit/branch/tag, indicates which commit will be loaded to the webhook payload.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/hooks/{id}/tests") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ref": $ref} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Get available issue templates for a repository
#
# GET /repos/{owner}/{repo}/issue_templates
# operationId: repoGetIssueTemplates
export def "repos-issue-templates get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/issue_templates") $auth.query)
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

# List a repository's issues
#
# GET /repos/{owner}/{repo}/issues
# operationId: issueListIssues
export def "repos-issues list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # whether issue is open or closed
  --labels: string # comma separated list of labels. Fetch only issues that have any of this labels. Non existent labels are discarded
  --q: string # search string
  --type: string@type-completer-2 # filter by type (issues / pulls) if set
  --milestones: string # comma separated list of milestone names or ids. It uses names and fall back to ids. Fetch only issues that have any of this milestones. Non existent milestones are discarded
  --since: string # Only show items updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show items updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --created-by: string # Only show items which were created by the the given user
  --assigned-by: string # Only show items for which the given user is assigned
  --mentioned-by: string # Only show items in which the given user was mentioned
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "milestones" $milestones "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "assigned_by" $assigned_by "scalar") (serialize-qp "mentioned_by" $mentioned_by "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/issues") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state, "labels": $labels, "q": $q, "type": $type, "milestones": $milestones, "since": $since, "before": $before, "created_by": $created_by, "assigned_by": $assigned_by, "mentioned_by": $mentioned_by, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an issue. If using deadline only the date will be taken into account, and time of day ignored.
#
# POST /repos/{owner}/{repo}/issues
# operationId: issueCreateIssue
export def "repos-issues create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee: string # deprecated
  --assignees: list<string>
  --body: string
  --closed: oneof<nothing, bool>
  --due-date: string # format: date-time
  --labels: list<int> # list of label ids
  --milestone: int # milestone id (format: int64)
  --ref: string
  title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/issues") $auth.query)
  let req_body = {"assignee": $assignee, "assignees": $assignees, "body": $body, "closed": $closed, "due_date": $due_date, "labels": $labels, "milestone": $milestone, "ref": $ref, "title": $title} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all comments in a repository
#
# GET /repos/{owner}/{repo}/issues/comments
# operationId: issueGetRepoComments
export def "repos-issues-comments get-by-owner-repo" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # if provided, only comments updated since the provided time are returned. (format: date-time)
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/issues/comments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"since": $since, "before": $before, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a comment
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}
# operationId: issueDeleteComment
export def "repos-issues-comments delete" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a comment
#
# GET /repos/{owner}/{repo}/issues/comments/{id}
# operationId: issueGetComment
export def "repos-issues-comments get-by-owner-repo-id" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Edit a comment
#
# PATCH /repos/{owner}/{repo}/issues/comments/{id}
# operationId: issueEditComment
export def "repos-issues-comments update-edit" [
  owner: string
  repo: string
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
  body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}") $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# List comment's attachments
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/assets
# operationId: issueListIssueCommentAttachments
export def "repos-issues-comments-assets list-attachments" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/assets") $auth.query)
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

# Create a comment attachment
#
# POST /repos/{owner}/{repo}/issues/comments/{id}/assets
# operationId: issueCreateIssueCommentAttachment
export def "repos-issues-comments-assets create-attachment" [
  owner: string
  repo: string
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
  --name: string # name of the attachment
  attachment: string # attachment to upload (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/assets") $qp $auth.query)
  let req_body = {"attachment": $attachment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["attachment"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"name": $name} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# Delete a comment attachment
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# operationId: issueDeleteIssueCommentAttachment
export def "repos-issues-comments-assets delete" [
  owner: string
  repo: string
  id: int
  attachment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a comment attachment
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# operationId: issueGetIssueCommentAttachment
export def "repos-issues-comments-assets get" [
  owner: string
  repo: string
  id: int
  attachment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}") $auth.query)
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

# Edit a comment attachment
#
# PATCH /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# operationId: issueEditIssueCommentAttachment
export def "repos-issues-comments-assets update-edit" [
  owner: string
  repo: string
  id: int
  attachment_id: int
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Remove a reaction from a comment of an issue
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}/reactions
# operationId: issueDeleteCommentReaction
export def "repos-issues-comments-reactions delete" [
  owner: string
  repo: string
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
  --content: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/reactions") $auth.query)
  let req_body = {"content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list of reactions from a comment of an issue
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/reactions
# operationId: issueGetCommentReactions
export def "repos-issues-comments-reactions get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/reactions") $auth.query)
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

# Add a reaction to a comment of an issue
#
# POST /repos/{owner}/{repo}/issues/comments/{id}/reactions
# operationId: issuePostCommentReaction
export def "repos-issues-comments-reactions create" [
  owner: string
  repo: string
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
  --content: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/comments/{id}/reactions") $auth.query)
  let req_body = {"content": $content} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Delete an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}
# operationId: issueDelete
export def "repos-issues delete" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an issue
#
# GET /repos/{owner}/{repo}/issues/{index}
# operationId: issueGetIssue
export def "repos-issues get" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}") $auth.query)
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

# Edit an issue. If using deadline only the date will be taken into account, and time of day ignored.
#
# PATCH /repos/{owner}/{repo}/issues/{index}
# operationId: issueEditIssue
export def "repos-issues update-edit" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee: string # deprecated
  --assignees: list<string>
  --body: string
  --due-date: string # format: date-time
  --milestone: int # format: int64
  --ref: string
  --state: string
  --title: string
  --unset-due-date: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}") $auth.query)
  let req_body = {"assignee": $assignee, "assignees": $assignees, "body": $body, "due_date": $due_date, "milestone": $milestone, "ref": $ref, "state": $state, "title": $title, "unset_due_date": $unset_due_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# List issue's attachments
#
# GET /repos/{owner}/{repo}/issues/{index}/assets
# operationId: issueListIssueAttachments
export def "repos-issues-assets list-attachments" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/assets") $auth.query)
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

# Create an issue attachment
#
# POST /repos/{owner}/{repo}/issues/{index}/assets
# operationId: issueCreateIssueAttachment
export def "repos-issues-assets create-attachment" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # name of the attachment
  attachment: string # attachment to upload (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/assets") $qp $auth.query)
  let req_body = {"attachment": $attachment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["attachment"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"name": $name} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# Delete an issue attachment
#
# DELETE /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# operationId: issueDeleteIssueAttachment
export def "repos-issues-assets delete" [
  owner: string
  repo: string
  index: int
  attachment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an issue attachment
#
# GET /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# operationId: issueGetIssueAttachment
export def "repos-issues-assets get" [
  owner: string
  repo: string
  index: int
  attachment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}") $auth.query)
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

# Edit an issue attachment
#
# PATCH /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# operationId: issueEditIssueAttachment
export def "repos-issues-assets update-edit" [
  owner: string
  repo: string
  index: int
  attachment_id: int
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all comments on an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/comments
# operationId: issueGetComments
export def "repos-issues-comments get-by-owner-repo-index" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # if provided, only comments updated since the specified time are returned. (format: date-time)
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/comments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"since": $since, "before": $before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a comment to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/comments
# operationId: issueCreateComment
export def "repos-issues-comments create" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/comments") $auth.query)
  let req_body = {"body": $body} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a comment
#
# DELETE /repos/{owner}/{repo}/issues/{index}/comments/{id}
# DEPRECATED
# operationId: issueDeleteCommentDeprecated
@deprecated
export def "repos-issues-comments delete-deprecated" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/{index}/comments/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Edit a comment
#
# PATCH /repos/{owner}/{repo}/issues/{index}/comments/{id}
# DEPRECATED
# operationId: issueEditCommentDeprecated
@deprecated
export def "repos-issues-comments update-edit-deprecated" [
  owner: string
  repo: string
  index: int
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
  body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/{index}/comments/{id}") $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Set an issue deadline. If set to null, the deadline is deleted. If using deadline only the date will be taken into account, and time of day ignored.
#
# POST /repos/{owner}/{repo}/issues/{index}/deadline
# operationId: issueEditIssueDeadline
export def "repos-issues-deadline create-edit" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  due_date: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/deadline") $auth.query)
  let req_body = {"due_date": $due_date} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Remove all labels from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueClearLabels
export def "repos-issues-labels delete-clear" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/labels") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an issue's labels
#
# GET /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueGetLabels
export def "repos-issues-labels get" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/labels") $auth.query)
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

# Add a label to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueAddLabel
export def "repos-issues-labels create" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: list<int> # list of label IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/labels") $auth.query)
  let req_body = {"labels": $labels} | compact
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

# Replace an issue's labels
#
# PUT /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueReplaceLabels
export def "repos-issues-labels update" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: list<int> # list of label IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/labels") $auth.query)
  let req_body = {"labels": $labels} | compact
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

# Remove a label from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/labels/{id}
# operationId: issueRemoveLabel
export def "repos-issues-labels delete" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/{index}/labels/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Remove a reaction from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/reactions
# operationId: issueDeleteIssueReaction
export def "repos-issues-reactions delete" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/reactions") $auth.query)
  let req_body = {"content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list reactions of an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/reactions
# operationId: issueGetIssueReactions
export def "repos-issues-reactions get" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/reactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a reaction to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/reactions
# operationId: issuePostIssueReaction
export def "repos-issues-reactions create" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/reactions") $auth.query)
  let req_body = {"content": $content} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Delete an issue's existing stopwatch.
#
# DELETE /repos/{owner}/{repo}/issues/{index}/stopwatch/delete
# operationId: issueDeleteStopWatch
export def "repos-issues-stopwatch-delete stop-watch" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/stopwatch/delete") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Start stopwatch on an issue.
#
# POST /repos/{owner}/{repo}/issues/{index}/stopwatch/start
# operationId: issueStartStopWatch
export def "repos-issues-stopwatch-start stop-watch" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/stopwatch/start") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Stop an issue's existing stopwatch.
#
# POST /repos/{owner}/{repo}/issues/{index}/stopwatch/stop
# operationId: issueStopStopWatch
export def "repos-issues-stopwatch-stop watch" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/stopwatch/stop") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Get users who subscribed on an issue.
#
# GET /repos/{owner}/{repo}/issues/{index}/subscriptions
# operationId: issueSubscriptions
export def "repos-issues-subscriptions get" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/subscriptions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Check if user is subscribed to an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/subscriptions/check
# operationId: issueCheckSubscription
export def "repos-issues-subscriptions-check check" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/subscriptions/check") $auth.query)
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

# Unsubscribe user from issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/subscriptions/{user}
# operationId: issueDeleteSubscription
export def "repos-issues-subscriptions delete" [
  owner: string
  repo: string
  index: int
  user: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), user: (encode-path-segment $user)} | format pattern "/repos/{owner}/{repo}/issues/{index}/subscriptions/{user}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 201 304]
}

# Subscribe user to issue
#
# PUT /repos/{owner}/{repo}/issues/{index}/subscriptions/{user}
# operationId: issueAddSubscription
export def "repos-issues-subscriptions create" [
  owner: string
  repo: string
  index: int
  user: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), user: (encode-path-segment $user)} | format pattern "/repos/{owner}/{repo}/issues/{index}/subscriptions/{user}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [200 201 304]
}

# List all comments and events on an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/timeline
# operationId: issueGetCommentsAndTimeline
export def "repos-issues-timeline get-comments-and" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # if provided, only comments updated since the specified time are returned. (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/timeline") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"since": $since, "page": $page, "limit": $limit, "before": $before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Reset a tracked time of an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/times
# operationId: issueResetTime
export def "repos-issues-times reset" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/times") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List an issue's tracked times
#
# GET /repos/{owner}/{repo}/issues/{index}/times
# operationId: issueTrackedTimes
export def "repos-issues-times get-tracked" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # optional filter by user (available for issue managers)
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/times") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user": $user, "since": $since, "before": $before, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add tracked time to a issue
#
# POST /repos/{owner}/{repo}/issues/{index}/times
# operationId: issueAddTime
export def "repos-issues-times create" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created: string # format: date-time
  time: int # time in seconds (format: int64)
  --user-name: string # User who spent the time (optional)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/issues/{index}/times") $auth.query)
  let req_body = {"created": $created, "time": $time, "user_name": $user_name} | compact
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

# Delete specific tracked time
#
# DELETE /repos/{owner}/{repo}/issues/{index}/times/{id}
# operationId: issueDeleteTime
export def "repos-issues-times delete" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/issues/{index}/times/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List a repository's keys
#
# GET /repos/{owner}/{repo}/keys
# operationId: repoListKeys
export def "repos-keys list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-id: int # the key_id to search for
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "key_id" $key_id "scalar") (serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/keys") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"key_id": $key_id, "fingerprint": $fingerprint, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a key to a repository
#
# POST /repos/{owner}/{repo}/keys
# operationId: repoCreateKey
export def "repos-keys create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/keys") $auth.query)
  let req_body = {"key": $key, "read_only": $read_only, "title": $title} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a key from a repository
#
# DELETE /repos/{owner}/{repo}/keys/{id}
# operationId: repoDeleteKey
export def "repos-keys delete" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/keys/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a repository's key by id
#
# GET /repos/{owner}/{repo}/keys/{id}
# operationId: repoGetKey
export def "repos-keys get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/keys/{id}") $auth.query)
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

# Get all of a repository's labels
#
# GET /repos/{owner}/{repo}/labels
# operationId: issueListLabels
export def "repos-labels list-issue" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/labels") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a label
#
# POST /repos/{owner}/{repo}/labels
# operationId: issueCreateLabel
export def "repos-labels create-issue" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/labels") $auth.query)
  let req_body = {"color": $color, "description": $description, "exclusive": $exclusive, "name": $name} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a label
#
# DELETE /repos/{owner}/{repo}/labels/{id}
# operationId: issueDeleteLabel
export def "repos-labels delete-issue" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/labels/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a single label
#
# GET /repos/{owner}/{repo}/labels/{id}
# operationId: issueGetLabel
export def "repos-labels get-issue" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/labels/{id}") $auth.query)
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

# Update a label
#
# PATCH /repos/{owner}/{repo}/labels/{id}
# operationId: issueEditLabel
export def "repos-labels update-issue-edit" [
  owner: string
  repo: string
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
  --color: string # e.g. #00aabb
  --description: string
  --exclusive: oneof<nothing, bool> # e.g. false
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/labels/{id}") $auth.query)
  let req_body = {"color": $color, "description": $description, "exclusive": $exclusive, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get languages and number of bytes of code written
#
# GET /repos/{owner}/{repo}/languages
# operationId: repoGetLanguages
export def "repos-languages get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/languages") $auth.query)
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

# Get a file or it's LFS object from a repository
#
# GET /repos/{owner}/{repo}/media/{filepath}
# operationId: repoGetRawFileOrLFS
export def "repos-media get-raw-file-or-lfs" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($filepath | is-empty) { error make --unspanned { msg: "path parameter 'filepath' must be non-empty" } }
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), filepath: (encode-path-segment $filepath)} | format pattern "/repos/{owner}/{repo}/media/{filepath}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ref": $ref} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all of a repository's opened milestones
#
# GET /repos/{owner}/{repo}/milestones
# operationId: issueGetMilestonesList
export def "repos-milestones get-issue-list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Milestone state, Recognized values are open, closed and all. Defaults to "open"
  --name: string # filter by milestone name
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/milestones") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state, "name": $name, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a milestone
#
# POST /repos/{owner}/{repo}/milestones
# operationId: issueCreateMilestone
export def "repos-milestones create-issue" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --due-on: string # format: date-time
  --state: string@state-completer-2
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/milestones") $auth.query)
  let req_body = {"description": $description, "due_on": $due_on, "state": $state, "title": $title} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a milestone
#
# DELETE /repos/{owner}/{repo}/milestones/{id}
# operationId: issueDeleteMilestone
export def "repos-milestones delete-issue" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/milestones/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a milestone
#
# GET /repos/{owner}/{repo}/milestones/{id}
# operationId: issueGetMilestone
export def "repos-milestones get-issue" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/milestones/{id}") $auth.query)
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

# Update a milestone
#
# PATCH /repos/{owner}/{repo}/milestones/{id}
# operationId: issueEditMilestone
export def "repos-milestones update-issue-edit" [
  owner: string
  repo: string
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
  --description: string
  --due-on: string # format: date-time
  --state: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/milestones/{id}") $auth.query)
  let req_body = {"description": $description, "due_on": $due_on, "state": $state, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sync a mirrored repository
#
# POST /repos/{owner}/{repo}/mirror-sync
# operationId: repoMirrorSync
export def "repos-mirror-sync sync" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/mirror-sync") $auth.query)
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

# List users's notification threads on a specific repo
#
# GET /repos/{owner}/{repo}/notifications
# operationId: notifyGetRepoList
export def "repos-notifications notify-get-list-by-owner-repo" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # If true, show notifications marked as read. Default value is false
  --status-types: list<string> # Show notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread & pinned
  --subject-type: list<string> # filter notifications by subject type
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "subject-type" $subject_type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/notifications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"all": $all, "status-types": $status_types, "subject-type": $subject_type, "since": $since, "before": $before, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Mark notification threads as read, pinned or unread on a specific repo
#
# PUT /repos/{owner}/{repo}/notifications
# operationId: notifyReadRepoList
export def "repos-notifications notify-get-list-by-owner-repo-1" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: string # If true, mark all notifications on this repo. Default value is false
  --status-types: list<string> # Mark notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread.
  --to-status: string # Status to mark notifications as. Defaults to read.
  --last-read-at: string # Describes the last point that notifications were checked. Anything updated since this time will not be updated. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "to-status" $to_status "scalar") (serialize-qp "last_read_at" $last_read_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/notifications") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"all": $all, "status-types": $status_types, "to-status": $to_status, "last_read_at": $last_read_at} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [205]
}

# List a repo's pull requests
#
# GET /repos/{owner}/{repo}/pulls
# operationId: repoListPullRequests
export def "repos-pulls list-requests" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # State of pull request: open or closed (optional)
  --qp-sort: string@sort-completer-1 # Type of sort
  --milestone: int # ID of the milestone (format: int64)
  --labels: list<int> # Label IDs
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "milestone" $milestone "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/pulls") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state, "sort": $qp_sort, "milestone": $milestone, "labels": $labels, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a pull request
#
# POST /repos/{owner}/{repo}/pulls
# operationId: repoCreatePullRequest
export def "repos-pulls create-request" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee: string
  --assignees: list<string>
  --body-base: string
  --body: string
  --due-date: string # format: date-time
  --head: string
  --labels: list<int>
  --milestone: int # format: int64
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/pulls") $auth.query)
  let req_body = {"assignee": $assignee, "assignees": $assignees, "base": $body_base, "body": $body, "due_date": $due_date, "head": $head, "labels": $labels, "milestone": $milestone, "title": $title} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}
# operationId: repoGetPullRequest
export def "repos-pulls get-request" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}") $auth.query)
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

# Update a pull request. If using deadline only the date will be taken into account, and time of day ignored.
#
# PATCH /repos/{owner}/{repo}/pulls/{index}
# operationId: repoEditPullRequest
export def "repos-pulls request-edit" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-maintainer-edit: oneof<nothing, bool>
  --assignee: string
  --assignees: list<string>
  --body-base: string
  --body: string
  --due-date: string # format: date-time
  --labels: list<int>
  --milestone: int # format: int64
  --state: string
  --title: string
  --unset-due-date: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}") $auth.query)
  let req_body = {"allow_maintainer_edit": $allow_maintainer_edit, "assignee": $assignee, "assignees": $assignees, "base": $body_base, "body": $body, "due_date": $due_date, "labels": $labels, "milestone": $milestone, "state": $state, "title": $title, "unset_due_date": $unset_due_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get a pull request diff or patch
#
# GET /repos/{owner}/{repo}/pulls/{index}.{diffType}
# operationId: repoDownloadPullDiffOrPatch
export def "repos-pulls download-diff-or-update" [
  owner: string
  repo: string
  index: int
  diff_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --binary: oneof<nothing, bool> # whether to include binary file changes. if true, the diff is applicable with `git apply`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($diff_type | is-empty) { error make --unspanned { msg: "path parameter 'diffType' must be non-empty" } }
  let qp = [(serialize-qp "binary" $binary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), diff_type: (encode-path-segment $diff_type)} | format pattern "/repos/{owner}/{repo}/pulls/{index}.{diff_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"binary": $binary} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get commits for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/commits
# operationId: repoGetPullRequestCommits
export def "repos-pulls-commits get-request" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/commits") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get changed files for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/files
# operationId: repoGetPullRequestFiles
export def "repos-pulls-files get-request" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-to: string # skip to given file
  --whitespace: string@whitespace-completer # whitespace behavior
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "skip-to" $skip_to "scalar") (serialize-qp "whitespace" $whitespace "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/files") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"skip-to": $skip_to, "whitespace": $whitespace, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cancel the scheduled auto merge for the given pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoCancelScheduledAutoMerge
export def "repos-pulls-merge cancel-scheduled-auto" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/merge") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Check if a pull request has been merged
#
# GET /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoPullRequestIsMerged
export def "repos-pulls-merge request-is-merged" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/merge") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Merge a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoMergePullRequest
export def "repos-pulls-merge request" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-do: string@do-completer
  --merge-commit-id: string
  --merge-message-field: string
  --merge-title-field: string
  --delete-branch-after-merge: oneof<nothing, bool>
  --force-merge: oneof<nothing, bool>
  --head-commit-id: string
  --merge-when-checks-succeed: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/merge") $auth.query)
  let req_body = {"Do": $body_do, "MergeCommitID": $merge_commit_id, "MergeMessageField": $merge_message_field, "MergeTitleField": $merge_title_field, "delete_branch_after_merge": $delete_branch_after_merge, "force_merge": $force_merge, "head_commit_id": $head_commit_id, "merge_when_checks_succeed": $merge_when_checks_succeed} | compact
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

# cancel review requests for a pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/requested_reviewers
# operationId: repoDeletePullReviewRequests
export def "repos-pulls-requested-reviewers delete-review-requests" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reviewers: list<string>
  --team-reviewers: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/requested_reviewers") $auth.query)
  let req_body = {"reviewers": $reviewers, "team_reviewers": $team_reviewers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# create review requests for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/requested_reviewers
# operationId: repoCreatePullReviewRequests
export def "repos-pulls-requested-reviewers create-review-requests" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reviewers: list<string>
  --team-reviewers: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/requested_reviewers") $auth.query)
  let req_body = {"reviewers": $reviewers, "team_reviewers": $team_reviewers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all reviews for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews
# operationId: repoListPullReviews
export def "repos-pulls-reviews list" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a review to an pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews
# operationId: repoCreatePullReview
# --comments item shape: {body?: string, new_position?: int, old_position?: int, path?: string}
export def "repos-pulls-reviews create" [
  owner: string
  repo: string
  index: int
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
  --comments: list # item shape: {body?: string, new_position?: int, old_position?: int, path?: string}
  --commit-id: string
  --event: string # ReviewStateType review state type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews") $auth.query)
  let req_body = {"body": $body, "comments": $comments, "commit_id": $commit_id, "event": $event} | compact
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

# Delete a specific review from a pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# operationId: repoDeletePullReview
export def "repos-pulls-reviews delete" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a specific review for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# operationId: repoGetPullReview
export def "repos-pulls-reviews get" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}") $auth.query)
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

# Submit a pending review to an pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# operationId: repoSubmitPullReview
export def "repos-pulls-reviews submit" [
  owner: string
  repo: string
  index: int
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
  --event: string # ReviewStateType review state type
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}") $auth.query)
  let req_body = {"body": $body, "event": $event} | compact
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

# Get a specific review for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/comments
# operationId: repoGetPullReviewComments
export def "repos-pulls-reviews-comments get" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}/comments") $auth.query)
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

# Dismiss a review for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/dismissals
# operationId: repoDismissPullReview
export def "repos-pulls-reviews-dismissals pull-dismiss" [
  owner: string
  repo: string
  index: int
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
  --message: string
  --priors: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}/dismissals") $auth.query)
  let req_body = {"message": $message, "priors": $priors} | compact
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

# Cancel to dismiss a review for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/undismissals
# operationId: repoUnDismissPullReview
export def "repos-pulls-reviews-undismissals pull-un-dismiss" [
  owner: string
  repo: string
  index: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/reviews/{id}/undismissals") $auth.query)
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

# Merge PR's baseBranch into headBranch
#
# POST /repos/{owner}/{repo}/pulls/{index}/update
# operationId: repoUpdatePullRequest
export def "repos-pulls-update request" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --style: string@style-completer # how to update pull request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "style" $style "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), index: (encode-path-segment $index)} | format pattern "/repos/{owner}/{repo}/pulls/{index}/update") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"style": $style} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get all push mirrors of the repository
#
# GET /repos/{owner}/{repo}/push_mirrors
# operationId: repoListPushMirrors
export def "repos-push-mirrors list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/push_mirrors") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# add a push mirror to the repository
#
# POST /repos/{owner}/{repo}/push_mirrors
# operationId: repoAddPushMirror
export def "repos-push-mirrors create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string
  --remote-address: string
  --remote-password: string
  --remote-username: string
  --sync-on-commit: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/push_mirrors") $auth.query)
  let req_body = {"interval": $interval, "remote_address": $remote_address, "remote_password": $remote_password, "remote_username": $remote_username, "sync_on_commit": $sync_on_commit} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Sync all push mirrored repository
#
# POST /repos/{owner}/{repo}/push_mirrors-sync
# operationId: repoPushMirrorSync
export def "repos-push-mirrors-sync push" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/push_mirrors-sync") $auth.query)
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

# deletes a push mirror from a repository by remoteName
#
# DELETE /repos/{owner}/{repo}/push_mirrors/{name}
# operationId: repoDeletePushMirror
export def "repos-push-mirrors delete" [
  owner: string
  repo: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), name: (encode-path-segment $name)} | format pattern "/repos/{owner}/{repo}/push_mirrors/{name}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get push mirror of the repository by remoteName
#
# GET /repos/{owner}/{repo}/push_mirrors/{name}
# operationId: repoGetPushMirrorByRemoteName
export def "repos-push-mirrors get-by-remote" [
  owner: string
  repo: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), name: (encode-path-segment $name)} | format pattern "/repos/{owner}/{repo}/push_mirrors/{name}") $auth.query)
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

# Get a file from a repository
#
# GET /repos/{owner}/{repo}/raw/{filepath}
# operationId: repoGetRawFile
export def "repos-raw get-file" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The name of the commit/branch/tag. Default the repository’s default branch (usually master)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($filepath | is-empty) { error make --unspanned { msg: "path parameter 'filepath' must be non-empty" } }
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), filepath: (encode-path-segment $filepath)} | format pattern "/repos/{owner}/{repo}/raw/{filepath}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ref": $ref} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List a repo's releases
#
# GET /repos/{owner}/{repo}/releases
# operationId: repoListReleases
export def "repos-releases list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --draft: oneof<nothing, bool> # filter (exclude / include) drafts, if you dont have repo write access none will show
  --pre-release: oneof<nothing, bool> # filter (exclude / include) pre-releases
  --per-page: int # page size of results, deprecated - use limit
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "draft" $draft "scalar") (serialize-qp "pre-release" $pre_release "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/releases") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"draft": $draft, "pre-release": $pre_release, "per_page": $per_page, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a release
#
# POST /repos/{owner}/{repo}/releases
# operationId: repoCreateRelease
export def "repos-releases create" [
  owner: string
  repo: string
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
  --draft: oneof<nothing, bool>
  --name: string
  --prerelease: oneof<nothing, bool>
  tag_name: string
  --target-commitish: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/releases") $auth.query)
  let req_body = {"body": $body, "draft": $draft, "name": $name, "prerelease": $prerelease, "tag_name": $tag_name, "target_commitish": $target_commitish} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets the most recent non-prerelease, non-draft release of a repository, sorted by created_at
#
# GET /repos/{owner}/{repo}/releases/latest
# operationId: repoGetLatestRelease
export def "repos-releases-latest get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/releases/latest") $auth.query)
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

# Delete a release by tag name
#
# DELETE /repos/{owner}/{repo}/releases/tags/{tag}
# operationId: repoDeleteReleaseByTag
export def "repos-releases-tags delete" [
  owner: string
  repo: string
  tag: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), tag: (encode-path-segment $tag)} | format pattern "/repos/{owner}/{repo}/releases/tags/{tag}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a release by tag name
#
# GET /repos/{owner}/{repo}/releases/tags/{tag}
# operationId: repoGetReleaseByTag
export def "repos-releases-tags get" [
  owner: string
  repo: string
  tag: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), tag: (encode-path-segment $tag)} | format pattern "/repos/{owner}/{repo}/releases/tags/{tag}") $auth.query)
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

# Delete a release
#
# DELETE /repos/{owner}/{repo}/releases/{id}
# operationId: repoDeleteRelease
export def "repos-releases delete" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/releases/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a release
#
# GET /repos/{owner}/{repo}/releases/{id}
# operationId: repoGetRelease
export def "repos-releases get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/releases/{id}") $auth.query)
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

# Update a release
#
# PATCH /repos/{owner}/{repo}/releases/{id}
# operationId: repoEditRelease
export def "repos-releases update-edit" [
  owner: string
  repo: string
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
  --draft: oneof<nothing, bool>
  --name: string
  --prerelease: oneof<nothing, bool>
  --tag-name: string
  --target-commitish: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/releases/{id}") $auth.query)
  let req_body = {"body": $body, "draft": $draft, "name": $name, "prerelease": $prerelease, "tag_name": $tag_name, "target_commitish": $target_commitish} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List release's attachments
#
# GET /repos/{owner}/{repo}/releases/{id}/assets
# operationId: repoListReleaseAttachments
export def "repos-releases-assets list-attachments" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/releases/{id}/assets") $auth.query)
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

# Create a release attachment
#
# POST /repos/{owner}/{repo}/releases/{id}/assets
# operationId: repoCreateReleaseAttachment
export def "repos-releases-assets create-attachment" [
  owner: string
  repo: string
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
  --name: string # name of the attachment
  attachment: string # attachment to upload (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id)} | format pattern "/repos/{owner}/{repo}/releases/{id}/assets") $qp $auth.query)
  let req_body = {"attachment": $attachment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["attachment"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"name": $name} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
}

# Delete a release attachment
#
# DELETE /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# operationId: repoDeleteReleaseAttachment
export def "repos-releases-assets delete" [
  owner: string
  repo: string
  id: int
  attachment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a release attachment
#
# GET /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# operationId: repoGetReleaseAttachment
export def "repos-releases-assets get" [
  owner: string
  repo: string
  id: int
  attachment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}") $auth.query)
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

# Edit a release attachment
#
# PATCH /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# operationId: repoEditReleaseAttachment
export def "repos-releases-assets update-edit" [
  owner: string
  repo: string
  id: int
  attachment_id: int
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Return all users that can be requested to review in this repo
#
# GET /repos/{owner}/{repo}/reviewers
# operationId: repoGetReviewers
export def "repos-reviewers get" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/reviewers") $auth.query)
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

# Get signing-key.gpg for given repository
#
# GET /repos/{owner}/{repo}/signing-key.gpg
# operationId: repoSigningKey
export def "repos-signing-key-gpg get" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/signing-key.gpg") $auth.query)
  let accept_val = "text/plain"
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

# List a repo's stargazers
#
# GET /repos/{owner}/{repo}/stargazers
# operationId: repoListStargazers
export def "repos-stargazers list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/stargazers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a commit's statuses
#
# GET /repos/{owner}/{repo}/statuses/{sha}
# operationId: repoListStatuses
export def "repos-statuses list" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer # type of sort
  --state: string@state-completer # type of state
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha)} | format pattern "/repos/{owner}/{repo}/statuses/{sha}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort": $qp_sort, "state": $state, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a commit status
#
# POST /repos/{owner}/{repo}/statuses/{sha}
# operationId: repoCreateStatus
export def "repos-statuses create-status" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: string
  --description: string
  --state: string # CommitStatusState holds the state of a CommitStatus It can be "pending", "success", "error", "failure", and "warning"
  --target-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($sha | is-empty) { error make --unspanned { msg: "path parameter 'sha' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), sha: (encode-path-segment $sha)} | format pattern "/repos/{owner}/{repo}/statuses/{sha}") $auth.query)
  let req_body = {"context": $context, "description": $description, "state": $state, "target_url": $target_url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List a repo's watchers
#
# GET /repos/{owner}/{repo}/subscribers
# operationId: repoListSubscribers
export def "repos-subscribers list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/subscribers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Unwatch a repo
#
# DELETE /repos/{owner}/{repo}/subscription
# operationId: userCurrentDeleteSubscription
export def "repos-subscription get-user-delete" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/subscription") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Check if the current user is watching a repo
#
# GET /repos/{owner}/{repo}/subscription
# operationId: userCurrentCheckSubscription
export def "repos-subscription get-user-check" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/subscription") $auth.query)
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

# Watch a repo
#
# PUT /repos/{owner}/{repo}/subscription
# operationId: userCurrentPutSubscription
export def "repos-subscription get-user-update" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/subscription") $auth.query)
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

# List a repository's tags
#
# GET /repos/{owner}/{repo}/tags
# operationId: repoListTags
export def "repos-tags list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results, default maximum page size is 50
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/tags") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new git tag in a repository
#
# POST /repos/{owner}/{repo}/tags
# operationId: repoCreateTag
export def "repos-tags create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string
  tag_name: string
  --target: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/tags") $auth.query)
  let req_body = {"message": $message, "tag_name": $tag_name, "target": $target} | compact
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

# Delete a repository's tag by name
#
# DELETE /repos/{owner}/{repo}/tags/{tag}
# operationId: repoDeleteTag
export def "repos-tags delete" [
  owner: string
  repo: string
  tag: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), tag: (encode-path-segment $tag)} | format pattern "/repos/{owner}/{repo}/tags/{tag}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the tag of a repository by tag name
#
# GET /repos/{owner}/{repo}/tags/{tag}
# operationId: repoGetTag
export def "repos-tags get" [
  owner: string
  repo: string
  tag: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), tag: (encode-path-segment $tag)} | format pattern "/repos/{owner}/{repo}/tags/{tag}") $auth.query)
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

# List a repository's teams
#
# GET /repos/{owner}/{repo}/teams
# operationId: repoListTeams
export def "repos-teams list" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/teams") $auth.query)
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

# Delete a team from a repository
#
# DELETE /repos/{owner}/{repo}/teams/{team}
# operationId: repoDeleteTeam
export def "repos-teams delete" [
  owner: string
  repo: string
  team: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), team: (encode-path-segment $team)} | format pattern "/repos/{owner}/{repo}/teams/{team}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Check if a team is assigned to a repository
#
# GET /repos/{owner}/{repo}/teams/{team}
# operationId: repoCheckTeam
export def "repos-teams check" [
  owner: string
  repo: string
  team: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), team: (encode-path-segment $team)} | format pattern "/repos/{owner}/{repo}/teams/{team}") $auth.query)
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

# Add a team to a repository
#
# PUT /repos/{owner}/{repo}/teams/{team}
# operationId: repoAddTeam
export def "repos-teams create" [
  owner: string
  repo: string
  team: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), team: (encode-path-segment $team)} | format pattern "/repos/{owner}/{repo}/teams/{team}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# List a repo's tracked times
#
# GET /repos/{owner}/{repo}/times
# operationId: repoTrackedTimes
export def "repos-times list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # optional filter by user (available for issue managers)
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/times") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"user": $user, "since": $since, "before": $before, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List a user's tracked times in a repo
#
# GET /repos/{owner}/{repo}/times/{user}
# DEPRECATED
# operationId: userTrackedTimes
@deprecated
export def "repos-times get-tracked" [
  owner: string
  repo: string
  user: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), user: (encode-path-segment $user)} | format pattern "/repos/{owner}/{repo}/times/{user}") $auth.query)
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

# Get list of topics that a repository has
#
# GET /repos/{owner}/{repo}/topics
# operationId: repoListTopics
export def "repos-topics list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/topics") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Replace list of topics for a repository
#
# PUT /repos/{owner}/{repo}/topics
# operationId: repoUpdateTopics
export def "repos-topics update" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topics: list<string> # list of topic names
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/topics") $auth.query)
  let req_body = {"topics": $topics} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete a topic from a repository
#
# DELETE /repos/{owner}/{repo}/topics/{topic}
# operationId: repoDeleteTopic
export def "repos-topics delete" [
  owner: string
  repo: string
  topic: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($topic | is-empty) { error make --unspanned { msg: "path parameter 'topic' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), topic: (encode-path-segment $topic)} | format pattern "/repos/{owner}/{repo}/topics/{topic}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add a topic to a repository
#
# PUT /repos/{owner}/{repo}/topics/{topic}
# operationId: repoAddTopic
export def "repos-topics create" [
  owner: string
  repo: string
  topic: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($topic | is-empty) { error make --unspanned { msg: "path parameter 'topic' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), topic: (encode-path-segment $topic)} | format pattern "/repos/{owner}/{repo}/topics/{topic}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Transfer a repo ownership
#
# POST /repos/{owner}/{repo}/transfer
# operationId: repoTransfer
export def "repos-transfer create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_owner: string
  --team-ids: list<int> # ID of the team or teams to add to the repository. Teams can only be added to organization-owned repositories.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/transfer") $auth.query)
  let req_body = {"new_owner": $new_owner, "team_ids": $team_ids} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Accept a repo transfer
#
# POST /repos/{owner}/{repo}/transfer/accept
# operationId: acceptRepoTransfer
export def "repos-transfer-accept create" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/transfer/accept") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Reject a repo transfer
#
# POST /repos/{owner}/{repo}/transfer/reject
# operationId: rejectRepoTransfer
export def "repos-transfer-reject reject" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/transfer/reject") $auth.query)
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

# Create a wiki page
#
# POST /repos/{owner}/{repo}/wiki/new
# operationId: repoCreateWikiPage
export def "repos-wiki-new create-page" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-base64: string # content must be base64 encoded
  --message: string # optional commit message summarizing the change
  --title: string # page title. leave empty to keep unchanged
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/wiki/new") $auth.query)
  let req_body = {"content_base64": $content_base64, "message": $message, "title": $title} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a wiki page
#
# DELETE /repos/{owner}/{repo}/wiki/page/{pageName}
# operationId: repoDeleteWikiPage
export def "repos-wiki-page delete" [
  owner: string
  repo: string
  page_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), page_name: (encode-path-segment $page_name)} | format pattern "/repos/{owner}/{repo}/wiki/page/{page_name}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a wiki page
#
# GET /repos/{owner}/{repo}/wiki/page/{pageName}
# operationId: repoGetWikiPage
export def "repos-wiki-page get" [
  owner: string
  repo: string
  page_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), page_name: (encode-path-segment $page_name)} | format pattern "/repos/{owner}/{repo}/wiki/page/{page_name}") $auth.query)
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

# Edit a wiki page
#
# PATCH /repos/{owner}/{repo}/wiki/page/{pageName}
# operationId: repoEditWikiPage
export def "repos-wiki-page update-edit" [
  owner: string
  repo: string
  page_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-base64: string # content must be base64 encoded
  --message: string # optional commit message summarizing the change
  --title: string # page title. leave empty to keep unchanged
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), page_name: (encode-path-segment $page_name)} | format pattern "/repos/{owner}/{repo}/wiki/page/{page_name}") $auth.query)
  let req_body = {"content_base64": $content_base64, "message": $message, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all wiki pages
#
# GET /repos/{owner}/{repo}/wiki/pages
# operationId: repoGetWikiPages
export def "repos-wiki-pages get" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/repos/{owner}/{repo}/wiki/pages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get revisions of a wiki page
#
# GET /repos/{owner}/{repo}/wiki/revisions/{pageName}
# operationId: repoGetWikiPageRevisions
export def "repos-wiki-revisions get-page" [
  owner: string
  repo: string
  page_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo), page_name: (encode-path-segment $page_name)} | format pattern "/repos/{owner}/{repo}/wiki/revisions/{page_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a repository using a template
#
# POST /repos/{template_owner}/{template_repo}/generate
# operationId: generateRepo
export def "repos-generate generate" [
  template_owner: string
  template_repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: oneof<nothing, bool> # include avatar of the template repo
  --default-branch: string # Default branch of the new repository
  --description: string # Description of the repository to create
  --git-content: oneof<nothing, bool> # include git content of default branch in template repo
  --git-hooks: oneof<nothing, bool> # include git hooks in template repo
  --labels: oneof<nothing, bool> # include labels in template repo
  name: string # Name of the repository to create
  owner: string # The organization or person who will own the new repository
  --private: oneof<nothing, bool> # Whether the repository is private
  --topics: oneof<nothing, bool> # include topics in template repo
  --webhooks: oneof<nothing, bool> # include webhooks in template repo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($template_owner | is-empty) { error make --unspanned { msg: "path parameter 'template_owner' must be non-empty" } }
  if ($template_repo | is-empty) { error make --unspanned { msg: "path parameter 'template_repo' must be non-empty" } }
  let full_url = (build-url $base ({template_owner: (encode-path-segment $template_owner), template_repo: (encode-path-segment $template_repo)} | format pattern "/repos/{template_owner}/{template_repo}/generate") $auth.query)
  let req_body = {"avatar": $avatar, "default_branch": $default_branch, "description": $description, "git_content": $git_content, "git_hooks": $git_hooks, "labels": $labels, "name": $name, "owner": $owner, "private": $private, "topics": $topics, "webhooks": $webhooks} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get a repository by id
#
# GET /repositories/{id}
# operationId: repoGetByID
export def "repositories get-repo" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/repositories/{id}") $auth.query)
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

# Get instance's global settings for api
#
# GET /settings/api
# operationId: getGeneralAPISettings
export def "settings get-general" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/api" $auth.query)
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

# Get instance's global settings for Attachment
#
# GET /settings/attachment
# operationId: getGeneralAttachmentSettings
export def "settings-attachment get-general" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/attachment" $auth.query)
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

# Get instance's global settings for repositories
#
# GET /settings/repository
# operationId: getGeneralRepositorySettings
export def "settings-repository get-general" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/repository" $auth.query)
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

# Get instance's global settings for ui
#
# GET /settings/ui
# operationId: getGeneralUISettings
export def "settings-ui get-general" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/ui" $auth.query)
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

# Get default signing-key.gpg
#
# GET /signing-key.gpg
# operationId: getSigningKey
export def "signing-key-gpg get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signing-key.gpg" $auth.query)
  let accept_val = "text/plain"
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

# Delete a team
#
# DELETE /teams/{id}
# operationId: orgDeleteTeam
export def "teams delete-org" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/teams/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a team
#
# GET /teams/{id}
# operationId: orgGetTeam
export def "teams get-org" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/teams/{id}") $auth.query)
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

# Edit a team
#
# PATCH /teams/{id}
# operationId: orgEditTeam
export def "teams update-org-edit" [
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
  --can-create-org-repo: oneof<nothing, bool>
  --description: string
  --includes-all-repositories: oneof<nothing, bool>
  name: string
  --permission: string@permission-completer
  --units: list<string> # e.g. [repo.code, repo.issues, repo.ext_issues, repo.wiki, repo.pulls, repo.releases, repo.projects, repo.ext_wiki]
  --units-map: record # e.g. {repo.code: read, repo.ext_issues: none, repo.ext_wiki: none, repo.issues: write, repo.projects: none, repo.pulls: owner, repo.releases: none, repo.wiki: admin}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/teams/{id}") $auth.query)
  let req_body = {"can_create_org_repo": $can_create_org_repo, "description": $description, "includes_all_repositories": $includes_all_repositories, "name": $name, "permission": $permission, "units": $units, "units_map": $units_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# List a team's members
#
# GET /teams/{id}/members
# operationId: orgListTeamMembers
export def "teams-members list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/teams/{id}/members") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove a team member
#
# DELETE /teams/{id}/members/{username}
# operationId: orgRemoveTeamMember
export def "teams-members delete-org" [
  id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), username: (encode-path-segment $username)} | format pattern "/teams/{id}/members/{username}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List a particular member of team
#
# GET /teams/{id}/members/{username}
# operationId: orgListTeamMember
export def "teams-members list-org" [
  id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), username: (encode-path-segment $username)} | format pattern "/teams/{id}/members/{username}") $auth.query)
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

# Add a team member
#
# PUT /teams/{id}/members/{username}
# operationId: orgAddTeamMember
export def "teams-members create-org" [
  id: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), username: (encode-path-segment $username)} | format pattern "/teams/{id}/members/{username}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# List a team's repos
#
# GET /teams/{id}/repos
# operationId: orgListTeamRepos
export def "teams-repos list-org" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/teams/{id}/repos") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove a repository from a team
#
# DELETE /teams/{id}/repos/{org}/{repo}
# operationId: orgRemoveTeamRepository
export def "teams-repos delete-repository" [
  id: int
  org: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), org: (encode-path-segment $org), repo: (encode-path-segment $repo)} | format pattern "/teams/{id}/repos/{org}/{repo}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List a particular repo of team
#
# GET /teams/{id}/repos/{org}/{repo}
# operationId: orgListTeamRepo
export def "teams-repos list" [
  id: int
  org: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), org: (encode-path-segment $org), repo: (encode-path-segment $repo)} | format pattern "/teams/{id}/repos/{org}/{repo}") $auth.query)
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

# Add a repository to a team
#
# PUT /teams/{id}/repos/{org}/{repo}
# operationId: orgAddTeamRepository
export def "teams-repos create-repository" [
  id: int
  org: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), org: (encode-path-segment $org), repo: (encode-path-segment $repo)} | format pattern "/teams/{id}/repos/{org}/{repo}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# search topics via keyword
#
# GET /topics/search
# operationId: topicSearch
export def "topics-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # keywords to search
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/topics/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the authenticated user
#
# GET /user
# operationId: userGetCurrent
export def "user get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user" $auth.query)
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

# List the authenticated user's oauth2 applications
#
# GET /user/applications/oauth2
# operationId: userGetOauth2Application
export def "user-applications-oauth2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/applications/oauth2" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# creates a new OAuth2 application
#
# POST /user/applications/oauth2
# operationId: userCreateOAuth2Application
export def "user-applications-oauth2 create-o-auth2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confidential-client: oneof<nothing, bool>
  --name: string
  --redirect-uris: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/applications/oauth2" $auth.query)
  let req_body = {"confidential_client": $confidential_client, "name": $name, "redirect_uris": $redirect_uris} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# delete an OAuth2 Application
#
# DELETE /user/applications/oauth2/{id}
# operationId: userDeleteOAuth2Application
export def "user-applications-oauth2 delete-o-auth2" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/applications/oauth2/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# get an OAuth2 Application
#
# GET /user/applications/oauth2/{id}
# operationId: userGetOAuth2Application
export def "user-applications-oauth2 get-o-auth2" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/applications/oauth2/{id}") $auth.query)
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

# update an OAuth2 Application, this includes regenerating the client secret
#
# PATCH /user/applications/oauth2/{id}
# operationId: userUpdateOAuth2Application
export def "user-applications-oauth2 update-o-auth2" [
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
  --confidential-client: oneof<nothing, bool>
  --name: string
  --redirect-uris: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/applications/oauth2/{id}") $auth.query)
  let req_body = {"confidential_client": $confidential_client, "name": $name, "redirect_uris": $redirect_uris} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete email addresses
#
# DELETE /user/emails
# operationId: userDeleteEmail
export def "user-emails delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list<string> # email addresses to delete
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails" $auth.query)
  let req_body = {"emails": $emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# List the authenticated user's email addresses
#
# GET /user/emails
# operationId: userListEmails
export def "user-emails list" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails" $auth.query)
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

# Add email addresses
#
# POST /user/emails
# operationId: userAddEmail
export def "user-emails create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list<string> # email addresses to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails" $auth.query)
  let req_body = {"emails": $emails} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List the authenticated user's followers
#
# GET /user/followers
# operationId: userCurrentListFollowers
export def "user-followers get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/followers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the users that the authenticated user is following
#
# GET /user/following
# operationId: userCurrentListFollowing
export def "user-following get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/following" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Unfollow a user
#
# DELETE /user/following/{username}
# operationId: userCurrentDeleteFollow
export def "user-following get-delete-follow" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/user/following/{username}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Check whether a user is followed by the authenticated user
#
# GET /user/following/{username}
# operationId: userCurrentCheckFollowing
export def "user-following get-check" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/user/following/{username}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Follow a user
#
# PUT /user/following/{username}
# operationId: userCurrentPutFollow
export def "user-following get-update-follow" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/user/following/{username}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Get a Token to verify
#
# GET /user/gpg_key_token
# operationId: getVerificationToken
export def "user-gpg-key-token get-verification" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/gpg_key_token" $auth.query)
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

# Verify a GPG key
#
# POST /user/gpg_key_verify
# operationId: userVerifyGPGKey
export def "user-gpg-key-verify verify" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/gpg_key_verify" $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# List the authenticated user's GPG keys
#
# GET /user/gpg_keys
# operationId: userCurrentListGPGKeys
export def "user-gpg-keys get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/gpg_keys" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a GPG key
#
# POST /user/gpg_keys
# operationId: userCurrentPostGPGKey
export def "user-gpg-keys get-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  armored_public_key: string # An armored GPG key to add
  --armored-signature: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/gpg_keys" $auth.query)
  let req_body = {"armored_public_key": $armored_public_key, "armored_signature": $armored_signature} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Remove a GPG key
#
# DELETE /user/gpg_keys/{id}
# operationId: userCurrentDeleteGPGKey
export def "user-gpg-keys get-delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/gpg_keys/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a GPG key
#
# GET /user/gpg_keys/{id}
# operationId: userCurrentGetGPGKey
export def "user-gpg-keys get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/gpg_keys/{id}") $auth.query)
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

# List the authenticated user's public keys
#
# GET /user/keys
# operationId: userCurrentListKeys
export def "user-keys get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/keys" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fingerprint": $fingerprint, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a public key
#
# POST /user/keys
# operationId: userCurrentPostKey
export def "user-keys get-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/keys" $auth.query)
  let req_body = {"key": $key, "read_only": $read_only, "title": $title} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a public key
#
# DELETE /user/keys/{id}
# operationId: userCurrentDeleteKey
export def "user-keys get-delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/keys/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a public key
#
# GET /user/keys/{id}
# operationId: userCurrentGetKey
export def "user-keys get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/keys/{id}") $auth.query)
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

# List the current user's organizations
#
# GET /user/orgs
# operationId: orgListCurrentUserOrgs
export def "user-orgs list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/orgs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the repos that the authenticated user owns
#
# GET /user/repos
# operationId: userCurrentListRepos
export def "user-repos get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/repos" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a repository
#
# POST /user/repos
# operationId: createCurrentUserRepo
export def "user-repos create-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/repos" $auth.query)
  let req_body = {"auto_init": $auto_init, "default_branch": $default_branch, "description": $description, "gitignores": $gitignores, "issue_labels": $issue_labels, "license": $license, "name": $name, "private": $private, "readme": $readme, "template": $template, "trust_model": $trust_model} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get user settings
#
# GET /user/settings
# operationId: getUserSettings
export def "user-settings get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/settings" $auth.query)
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

# Update user settings
#
# PATCH /user/settings
# operationId: updateUserSettings
export def "user-settings update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --diff-view-style: string
  --full-name: string
  --hide-activity: oneof<nothing, bool>
  --hide-email: oneof<nothing, bool> # Privacy
  --language: string
  --location: string
  --theme: string
  --website: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/settings" $auth.query)
  let req_body = {"description": $description, "diff_view_style": $diff_view_style, "full_name": $full_name, "hide_activity": $hide_activity, "hide_email": $hide_email, "language": $language, "location": $location, "theme": $theme, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# The repos that the authenticated user has starred
#
# GET /user/starred
# operationId: userCurrentListStarred
export def "user-starred get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/starred" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Unstar the given repo
#
# DELETE /user/starred/{owner}/{repo}
# operationId: userCurrentDeleteStar
export def "user-starred get-delete-star" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/user/starred/{owner}/{repo}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Whether the authenticated is starring the repo
#
# GET /user/starred/{owner}/{repo}
# operationId: userCurrentCheckStarring
export def "user-starred get-check-starring" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/user/starred/{owner}/{repo}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Star the given repo
#
# PUT /user/starred/{owner}/{repo}
# operationId: userCurrentPutStar
export def "user-starred get-update-star" [
  owner: string
  repo: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($owner | is-empty) { error make --unspanned { msg: "path parameter 'owner' must be non-empty" } }
  if ($repo | is-empty) { error make --unspanned { msg: "path parameter 'repo' must be non-empty" } }
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), repo: (encode-path-segment $repo)} | format pattern "/user/starred/{owner}/{repo}") $auth.query)
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
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Get list of all existing stopwatches
#
# GET /user/stopwatches
# operationId: userGetStopWatches
export def "user-stopwatches get-stop-watches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/stopwatches" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List repositories watched by the authenticated user
#
# GET /user/subscriptions
# operationId: userCurrentListSubscriptions
export def "user-subscriptions get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/subscriptions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all the teams a user belongs to
#
# GET /user/teams
# operationId: userListTeams
export def "user-teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/teams" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the current user's tracked times
#
# GET /user/times
# operationId: userCurrentTrackedTimes
export def "user-times get-tracked" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/times" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit, "since": $since, "before": $before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for users
#
# GET /users/search
# operationId: userSearch
export def "users-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # keyword
  --uid: int # ID of the user to search for (format: int64)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> record<data: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, starred_repos_count: int, visibility: string, website: string>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "uid" $uid "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "uid": $uid, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a user
#
# GET /users/{username}
# operationId: userGet
export def "users get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}") $auth.query)
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

# List the given user's followers
#
# GET /users/{username}/followers
# operationId: userListFollowers
export def "users-followers list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/followers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the users that the given user is following
#
# GET /users/{username}/following
# operationId: userListFollowing
export def "users-following list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/following") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Check if one user is following another user
#
# GET /users/{username}/following/{target}
# operationId: userCheckFollowing
export def "users-following check" [
  username: string
  target: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($target | is-empty) { error make --unspanned { msg: "path parameter 'target' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), target: (encode-path-segment $target)} | format pattern "/users/{username}/following/{target}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# List the given user's GPG keys
#
# GET /users/{username}/gpg_keys
# operationId: userListGPGKeys
export def "users-gpg-keys list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/gpg_keys") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a user's heatmap
#
# GET /users/{username}/heatmap
# operationId: userGetHeatmapData
export def "users-heatmap get-data" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/heatmap") $auth.query)
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

# List the given user's public keys
#
# GET /users/{username}/keys
# operationId: userListKeys
export def "users-keys list" [
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
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/keys") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fingerprint": $fingerprint, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List a user's organizations
#
# GET /users/{username}/orgs
# operationId: orgListUserOrgs
export def "users-orgs list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/orgs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get user permissions in organization
#
# GET /users/{username}/orgs/{org}/permissions
# operationId: orgGetUserPermissions
export def "users-orgs-permissions get" [
  username: string
  org: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($org | is-empty) { error make --unspanned { msg: "path parameter 'org' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), org: (encode-path-segment $org)} | format pattern "/users/{username}/orgs/{org}/permissions") $auth.query)
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

# List the repos owned by the given user
#
# GET /users/{username}/repos
# operationId: userListRepos
export def "users-repos list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/repos") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The repos that the given user has starred
#
# GET /users/{username}/starred
# operationId: userListStarred
export def "users-starred list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/starred") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the repositories watched by a user
#
# GET /users/{username}/subscriptions
# operationId: userListSubscriptions
export def "users-subscriptions list" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/subscriptions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List the authenticated user's access tokens
#
# GET /users/{username}/tokens
# operationId: userGetTokens
export def "users-tokens get" [
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
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/tokens") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an access token
#
# POST /users/{username}/tokens
# operationId: userCreateToken
export def "users-tokens create" [
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
  name: string
  --scopes: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/users/{username}/tokens") $auth.query)
  let req_body = {"name": $name, "scopes": $scopes} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# delete an access token
#
# DELETE /users/{username}/tokens/{token}
# operationId: userDeleteAccessToken
export def "users-tokens delete-access" [
  username: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), token_arg: (encode-path-segment $token_arg)} | format pattern "/users/{username}/tokens/{token_arg}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns the version of the Gitea application
#
# GET /version
# operationId: getVersion
export def "version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version" $auth.query)
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
