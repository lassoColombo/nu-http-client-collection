# Auto-generated client for trash nothing v1.3
# Source: https://api.apis.guru/v2/specs/trashnothing.com/1.3/openapi.json
# Auth: --token flag or $env.TRASH_NOTHING_TOKEN

const BASE_URL = "https://trashnothing.com/api/v1.3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TRASH_NOTHING_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://trashnothing.com/api/v1.3"] }
def auth-scheme-completer [] { ["query-api_key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "conversations get" } } | get name | first)
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

# List conversations
#
# GET /conversations
# operationId: get_conversations
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
  --category: string # Used to filter messases by category. Must be set to one of the following three categories: inbox, archived, blocked (default: inbox)
  --page: int # The page of conversations to return. (default: 1)
  --per-page: int # The number of conversations to return per page (must be >= 1 and <= 30). (default: 10)
  --num-messages: int # The number of recent messages to return with each conversation. Additional messages can be retrieved using get conversation messages endpoint. (default: 10)
  --include-num-unread: int # If set to 1, the num_unread field in the response will be set to the count of the total number of conversations that have unread messages. This is useful for showing users the total number of unread messages that they have in their inbox. Calculating the count will slow the request down a bit so setting this should be avoided for requests where it's not needed (eg. requesting archived or blocked conversations or requests that are just paging through older conversations). (default: 0)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<conversations: table<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list, num_unread_messages: int, user: record>, num_unread: int, page: int, per_page: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "num_messages" $num_messages "scalar") (serialize-qp "include_num_unread" $include_num_unread "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category": $category, "page": $page, "per_page": $per_page, "num_messages": $num_messages, "include_num_unread": $include_num_unread, "device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Archive all conversations
#
# PUT /conversations/archive-all
# operationId: archive_all_conversations
export def "conversations-archive-all archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # The message_id of the most recent message from the conversations that the client has downloaded.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/archive-all" $auth.query)
  let req_body = {"message_id": $message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Mark all conversations as read
#
# PUT /conversations/mark-all-read
# operationId: mark_all_conversations_read
export def "conversations-mark-all-read list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # The message_id of the most recent message from the conversations that the client has downloaded.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/mark-all-read" $auth.query)
  let req_body = {"message_id": $message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Search conversations
#
# GET /conversations/search
# operationId: search_conversations
export def "conversations-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find conversations and messages.
  --page: int # The page of conversations to return. (default: 1)
  --per-page: int # The number of conversations to return per page (must be >= 1 and <= 30). (default: 10)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<conversations: table<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list, num_unread_messages: int, user: record>, page: int, per_page: int, search: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversations/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "page": $page, "per_page": $per_page, "device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete conversation
#
# DELETE /conversations/{conversation_id}
# operationId: delete_conversation
export def "conversations delete" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-id: string # The ID of the newest message in the conversation that the client has downloaded.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let qp = [(serialize-qp "message_id" $message_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"message_id": $message_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Archive conversation
#
# PUT /conversations/{conversation_id}/archive
# operationId: archive_conversation
export def "conversations-archive archive" [
  conversation_id: string
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
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/archive") $auth.query)
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

# Block conversation
#
# PUT /conversations/{conversation_id}/block
# operationId: block_conversation
export def "conversations-block update" [
  conversation_id: string
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
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/block") $auth.query)
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

# Mark conversation as read
#
# PUT /conversations/{conversation_id}/mark-read
# operationId: mark_conversation_read
export def "conversations-mark-read get" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # The ID of the newest message in the conversation that the current user has read.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/mark-read") $auth.query)
  let req_body = {"message_id": $message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# List conversation messages
#
# GET /conversations/{conversation_id}/messages
# operationId: get_conversation_messages
export def "conversations-messages get" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of messages to return. (default: 1)
  --per-page: int # The number of messages to return per page (must be >= 1 and <= 30). (default: 10)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --include-conversation: int # If set to 1, the conversation will be returned along with the messages. (default: 0)
]: nothing -> record<conversation: record<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list<record>, num_unread_messages: int, user: record<about_me: string, country: string, feedback: record, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>>, messages: table<content: string, date: string, email_attachments: list, from_user_id: string, message_id: string, photos: list, post: record, subject: string, to_user_id: string>, page: int, per_page: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar") (serialize-qp "include_conversation" $include_conversation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/messages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "device_pixel_ratio": $device_pixel_ratio, "include_conversation": $include_conversation} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Reply to conversation
#
# POST /conversations/{conversation_id}/reply
# operationId: reply_to_conversation
export def "conversations-reply create" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The content of the reply.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this message.
]: any -> record<content: string, date: string, email_attachments: list<string>, from_user_id: string, message_id: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list<record>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, subject: string, to_user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/reply") $auth.query)
  let req_body = {"content": $content, "device_pixel_ratio": $device_pixel_ratio, "photo_ids": $photo_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Report conversation
#
# POST /conversations/{conversation_id}/report
# operationId: report_conversation
export def "conversations-report create" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # A user provided reason why the conversation is being reported.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/report") $auth.query)
  let req_body = {"reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Unarchive conversation
#
# PUT /conversations/{conversation_id}/unarchive
# operationId: unarchive_conversation
export def "conversations-unarchive unarchive" [
  conversation_id: string
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
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/unarchive") $auth.query)
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

# Unblock conversation
#
# PUT /conversations/{conversation_id}/unblock
# operationId: unblock_conversation
export def "conversations-unblock update" [
  conversation_id: string
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
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversation_id' must be non-empty" } }
  let full_url = (build-url $base ({conversation_id: (encode-path-segment $conversation_id)} | format pattern "/conversations/{conversation_id}/unblock") $auth.query)
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

# Send feedback
#
# POST /feedback
# operationId: send_feedback
export def "feedback send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # The message.
  --meta: string # Extra information set by the client that may be useful to contextualize the feedback (eg. operating system details, browser details, app details, device details).
  subject: string # The subject.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/feedback" $auth.query)
  let req_body = {"message": $message, "meta": $meta, "subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Search groups
#
# GET /groups
# operationId: search_groups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Find groups that have the given text somewhere in their name (case insensitive).
  --latitude: float # Find groups near the given latitude and longitude.
  --longitude: float # Find groups near the given latitude and longitude.
  --distance: float # When latitude and longitude are passed, distance can optionally be passed to only return groups within a certain distance (in kilometers) from the point specified by the latitude and longitude. The distance must be > 0 and <= 150 and will default to 100. (default: 100)
  --country: string # Find groups in the given country where country is a 2 letter country code for the country (see https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 ).
  --region: string # For countries with regions (AU, CA, GB, US), search groups in a specific region as specified by the region abbreviation. The supported regions and their abbreviations are listed below. NOTE: The region and postal_code parameters cannot be used at the same time and if both are passed then the postal_code will take priority. --- **AU** - QLD: Queensland - SA: South Australia - TAS: Tasmania - VIC: Victoria - WA: Western Australia - NT: Northern Territory - NSW: New South Wales - ACT **CA** - AB: Alberta - BC: British Columbia - MB: Manitoba - NB: New Brunswick - NL: Newfoundland and Labrador - NS: Nova Scotia - ON: Ontario - QC: Quebec - SK: Saskatchewan - PE: Prince Edward Island **GB** - E: East - EM: East Midlands - LDN: London - NE: North East - NW: North West - NI: Northern Ireland - SC: Scotland - SE: South East - SW: South West - WA: Wales - WM: West Midlands - YH: Yorkshire and the Humber **US** All 50 states and the District of Columbia are supported. For the abbreviations, see: https://github.com/jasonong/List-of-US-States/blob/master/states.csv
  --postal-code: string # Find groups in the given postal code. Only a few countries support postal code searches (US, CA, AU, GB). The country parameter must be passed when the postal_code parameter is set. NOTE: The region and postal_code parameters cannot be used at the same time and if both are passed then the postal_code will take priority.
  --page: int # The page of groups to return. (default: 1)
  --per-page: int # The number of groups to return per page (must be >= 1 and <= 100). (default: 20)
]: nothing -> record<end_index: int, groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, num_groups: int, num_pages: int, page: int, per_page: int, start_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "distance" $distance "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "latitude": $latitude, "longitude": $longitude, "distance": $distance, "country": $country, "region": $region, "postal_code": $postal_code, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve multiple groups
#
# GET /groups/multiple
# operationId: get_groups_by_ids
export def "groups-multiple get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-ids: string # The IDs of the groups to retrieve. If more than 20 group IDs are passed, only the first 20 groups will be returned.
]: nothing -> table<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_ids" $group_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/multiple" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"group_ids": $group_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Join groups
#
# POST /groups/subscribe
# operationId: join_groups
export def "groups-subscribe create-join" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group_ids: string # A comma separated list of the IDs of the groups to join.
]: any -> record<groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, over_group_limit: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/subscribe" $auth.query)
  let req_body = {"group_ids": $group_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Retrieve a group
#
# GET /groups/{group_id}
# operationId: get_group
export def "groups get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}") $auth.query)
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

# Submit group answers
#
# POST /groups/{group_id}/answers
# operationId: submit_answers
export def "groups-answers submit" [
  group_id: string
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
]: any -> record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/answers") $auth.query)
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

# Contact group moderators
#
# POST /groups/{group_id}/contact
# operationId: contact_moderators
export def "groups-contact create-moderators" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # The body of the message.
  subject: string # The subject of the message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/contact") $auth.query)
  let req_body = {"message": $message, "subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Leave a group
#
# POST /groups/{group_id}/unsubscribe
# operationId: leave_group
export def "groups-unsubscribe create-leave" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/unsubscribe") $auth.query)
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

# Create a photo
#
# POST /photos
# operationId: upload_photo
export def "photos upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  photo: string # Photo to upload. (format: binary)
]: any -> record<photo_id: string, thumbnail: record<height: int, url: string, width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/photos" $auth.query)
  let req_body = {"device_pixel_ratio": $device_pixel_ratio, "photo": $photo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["photo"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Retrieve multiple photos
#
# GET /photos/multiple
# operationId: get_photos_by_ids
export def "photos-multiple get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --photo-ids: string # The IDs of the photos to retrieve. If more than 50 photo IDs are passed, only the first 50 photos will be returned.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> table<photo_id: string, thumbnail: record<height: int, url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "photo_ids" $photo_ids "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/photos/multiple" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"photo_ids": $photo_ids, "device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a photo
#
# DELETE /photos/{photo_id}
# operationId: delete_photo
export def "photos delete" [
  photo_id: string
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
  if ($photo_id | is-empty) { error make --unspanned { msg: "path parameter 'photo_id' must be non-empty" } }
  let full_url = (build-url $base ({photo_id: (encode-path-segment $photo_id)} | format pattern "/photos/{photo_id}") $auth.query)
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

# Rotate a photo
#
# POST /photos/{photo_id}/rotate
# operationId: rotate_photo
export def "photos-rotate create" [
  photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --degrees: int # Rotation in degrees - currently only 90, 180 and 270 are supported which correspond to rotate left, rotate upside down and rotate right.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<photo_id: string, thumbnail: record<height: int, url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($photo_id | is-empty) { error make --unspanned { msg: "path parameter 'photo_id' must be non-empty" } }
  let qp = [(serialize-qp "degrees" $degrees "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({photo_id: (encode-path-segment $photo_id)} | format pattern "/photos/{photo_id}/rotate") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"degrees": $degrees, "device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List posts
#
# GET /posts
# operationId: get_posts
export def "posts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # How to sort the posts that are returned. One of: date, active, distance Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: date)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required.
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. If unset, defaults to the current date and time minus 90 days. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. If unset, defaults to the current date and time. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: )
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: )
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "outcomes" $outcomes "scalar") (serialize-qp "user_state" $user_state "scalar") (serialize-qp "include_reposts" $include_reposts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort_by": $sort_by, "types": $types, "sources": $sources, "group_ids": $group_ids, "per_page": $per_page, "page": $page, "device_pixel_ratio": $device_pixel_ratio, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "date_min": $date_min, "date_max": $date_max, "outcomes": $outcomes, "user_state": $user_state, "include_reposts": $include_reposts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Submit a post
#
# POST /posts
# operationId: submit_post
export def "posts submit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # A longer description of the item(s).
  --expires-in: string # When the post should expire. Defaults to 90 days. Any amount of time from 1 hour to 90 days can be provided. To pass a number of hours, provide the number of hours prefixed by 'h' (eg. 1hr 24hr). To pass a number of days, provide the number of days prefixed by 'd' (eg. 1d 90d). Note that posts may not appear instantly after submission because the volunteer moderators of many groups may have additional automatic or manual review processes in place that can cause delays. So with short expirations (eg. < 8 hours), there is a chance that the post may expire before it's approved and so it will never be published.
  --fair-offer: int # If set to 1, the post will be posted with the Fair Offer Policy (only valid for offer posts - see https://trashnothing.com/fair_offer_policy ). (default: 0)
  --group-ids: string # A comma separated list of group IDs to submit the post to (if any).
  --latitude: float # The latitude corresponding to the location description provided. If latitude and longitude are not provided, an attempt will be made to automatically geocode the location. If the location is unable to be geocoded, the post will be rejected* and will have to be resubmitted with a latitude and longitude corresponding to the location or resubmitted with a different location that can be automatically geocoded. NOTE: The latitude and longitude should NOT be the users' exact location because we don't want to publicize their exact location unless their location description is their full address (which is not recommended). *When a post is rejected because it can't be geocoded, the returned error will have its identifier property set to 'unknown-location'.
  location: string # A short location description.
  --longitude: float # The longitude corresponding to the location description provided. (see the NOTE in latitude description)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this post.
  --preferences: string # A JSON string representing a permanent object that the client persists and modifies based on warnings returned by the post submission process and user input. Some warnings returned after submitting a post have a preference_key string property so that users can opt out of those warnings in the future. To save this opt-out preference, set the property indicated by the preference_key in the preferences object (eg. preferences[preference_key] = 1). The preferences object is never modified by the server - it is up to the client to initialize, modify and persist the preferences object.
  --repost: string # If the post is a repost of an existing post, this should be set to the post_id of the post that is being reposted.
  --reselling: string # For wanted posts only. If set to 1, the wanted post will show that the poster intends to resell any items that they receive in response to this post. Posters must declare if they intend to resell items.
  session: string # A JSON string representing a temporary object that is used to store data about the submission process for a single post. The first time a post is submitted, session should be a new empty object (eg. '{}'). The session object should be persisted by the client until that post is successfully submitted and then it can be discarded so that the next post will start over with a new empty session object. Every time a post is submitted and the response indicates that the submission was not successful, the session object returned in the response should override the clients copy of the session.
  title: string # A short description of the item(s).
  type: string # The type of post. One of: offer, wanted
]: any -> record<identifier: string, message: string, preference_key: string, result: string, session: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/posts" $auth.query)
  let req_body = {"content": $content, "expires_in": $expires_in, "fair_offer": $fair_offer, "group_ids": $group_ids, "latitude": $latitude, "location": $location, "longitude": $longitude, "photo_ids": $photo_ids, "preferences": $preferences, "repost": $repost, "reselling": $reselling, "session": $session, "title": $title, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# List all posts
#
# GET /posts/all
# operationId: get_all_posts
export def "posts-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --types: string # A comma separated list of the post types to return. The available post types are: offer, wanted
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_max. And the date and time must be within the last 30 days. And the date and time must be rounded to the nearest second. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_min. And the date and time must be rounded to the nearest second. (format: date-time)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 50). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "types" $types "scalar") (serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts/all" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"types": $types, "date_min": $date_min, "date_max": $date_max, "per_page": $per_page, "page": $page, "device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all post changes
#
# GET /posts/all/changes
# operationId: get_all_posts_changes
export def "posts-all-changes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-min: string # Only changes newer than or equal to this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_max. And the date and time must be within the last 30 days. And the date and time must be rounded to the nearest second. (format: date-time)
  --date-max: string # Only changes older than this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_min. And the date and time must be rounded to the nearest second. (format: date-time)
  --per-page: int # The number of changes to return per page (must be >= 1 and <= 50). (default: 20)
  --page: int # The page of changes to return. (default: 1)
]: nothing -> record<changes: table<date: string, post_id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts/all/changes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"date_min": $date_min, "date_max": $date_max, "per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve multiple posts
#
# GET /posts/multiple
# operationId: get_posts_by_ids
export def "posts-multiple get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --post-ids: string # A comma separated list of the post IDs. If more than 10 post IDs are passed, only the first 10 posts will be returned.
]: nothing -> record<forbidden: list<string>, not_found: list<string>, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "post_ids" $post_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts/multiple" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"post_ids": $post_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search posts
#
# GET /posts/search
# operationId: search_posts
export def "posts-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find posts.
  --sort-by: string # How to sort the posts that are returned. One of: relevance, date, active, distance Relevance sorting will sort the posts that best match the search query first. Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: relevance)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required.
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. If unset, defaults to the current date and time minus 90 days. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. If unset, defaults to the current date and time. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: )
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: )
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "outcomes" $outcomes "scalar") (serialize-qp "user_state" $user_state "scalar") (serialize-qp "include_reposts" $include_reposts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/posts/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "sort_by": $sort_by, "types": $types, "sources": $sources, "group_ids": $group_ids, "per_page": $per_page, "page": $page, "device_pixel_ratio": $device_pixel_ratio, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "date_min": $date_min, "date_max": $date_max, "outcomes": $outcomes, "user_state": $user_state, "include_reposts": $include_reposts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a post
#
# DELETE /posts/{post_id}
# operationId: delete_post
export def "posts delete" [
  post_id: string
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
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}") $auth.query)
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

# Retrieve a post
#
# GET /posts/{post_id}
# operationId: get_post
export def "posts get" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}") $auth.query)
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

# Update a post
#
# PUT /posts/{post_id}
# operationId: update_post
export def "posts update" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # A longer description of the item(s).
  --expires-in: string # When the post should expire. Any amount of time from 1 hour to 90 days can be provided. To pass a number of hours, provide the number of hours prefixed by 'h' (eg. 1hr 24hr). To pass a number of days, provide the number of days prefixed by 'd' (eg. 1d 90d). Note that updates may not appear instantly after submission because the volunteer moderators of many groups may have additional automatic or manual review processes in place that can cause delays. So with short expirations (eg. < 8 hours), there is a chance that the post may expire before the update is approved and so it will never be published. NOTE: The max expiration for a post is 90 days after the post is published. So updates to posts that try to set an longer expiration will be silently changed to just apply the max expiration.
  --fair-offer: int # If set to 1, the post will be posted with the Fair Offer Policy (only valid for offer posts - see https://trashnothing.com/fair_offer_policy ). (default: 0)
  --latitude: float # The latitude corresponding to the location description provided. If latitude and longitude are not provided, an attempt will be made to automatically geocode the location. If the location is unable to be geocoded, the post will be rejected* and will have to be resubmitted with a latitude and longitude corresponding to the location or resubmitted with a different location that can be automatically geocoded. NOTE: The latitude and longitude should NOT be the users' exact location because we don't want to publicize their exact location unless their location description is their full address (which is not recommended). *When a post is rejected because it can't be geocoded, the returned error will have its identifier property set to 'unknown-location'.
  location: string # A short location description.
  --longitude: float # The longitude corresponding to the location description provided. (see the NOTE in latitude description)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this post.
  --preferences: string # A JSON string representing a permanent object that the client persists and modifies based on warnings returned by the update submission process and user input. Some warnings returned after submitting an update have a preference_key string property so that users can opt out of those warnings in the future. To save this opt-out preference, set the property indicated by the preference_key in the preferences object (eg. preferences[preference_key] = 1). The preferences object is never modified by the server - it is up to the client to initialize, modify and persist the preferences object.
  --reselling: string # For wanted posts only. If set to 1, the wanted post will show that the poster intends to resell any items that they receive in response to this post. Posters must declare if they intend to resell items.
  session: string # A JSON string representing a temporary object that is used to store data about the update process for a single post. The first time a post update is submitted, session should be a new empty object (eg. '{}'). The session object should be persisted by the client until that update is successfully submitted and then it can be discarded so that the next update will start over with a new empty session object. Every time an update is submitted and the response indicates that the submission was not successful, the session object returned in the response should override the clients copy of the session.
  title: string # A short description of the item(s).
  type: string # The type of post. One of: offer, wanted
]: any -> record<identifier: string, message: string, preference_key: string, result: string, session: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}") $auth.query)
  let req_body = {"content": $content, "expires_in": $expires_in, "fair_offer": $fair_offer, "latitude": $latitude, "location": $location, "longitude": $longitude, "photo_ids": $photo_ids, "preferences": $preferences, "reselling": $reselling, "session": $session, "title": $title, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Delete a post bookmark
#
# DELETE /posts/{post_id}/bookmark
# operationId: delete_bookmark
export def "posts-bookmark delete" [
  post_id: string
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
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/bookmark") $auth.query)
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

# Bookmark a post
#
# PUT /posts/{post_id}/bookmark
# operationId: bookmark_post
export def "posts-bookmark create" [
  post_id: string
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
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/bookmark") $auth.query)
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

# Retrieve post display data
#
# GET /posts/{post_id}/display
# operationId: get_post_and_related_data
export def "posts-display get-and-related-data" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, author_offer_count: int, author_posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, author_wanted_count: int, bookmarked: bool, feedback: table<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, post: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list<record>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, replied: bool, user_can_reply: bool, viewed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/display") $auth.query)
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

# Promise an offer post
#
# PUT /posts/{post_id}/promise
# operationId: promise_post
export def "posts-promise create" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/promise") $auth.query)
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

# Reply to a post
#
# POST /posts/{post_id}/reply
# operationId: reply_to_post
export def "posts-reply create" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # The message to send to the post author.
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this reply.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/reply") $auth.query)
  let req_body = {"message": $message, "photo_ids": $photo_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Report a post
#
# POST /posts/{post_id}/report
# operationId: report_post
export def "posts-report create" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: string # An explanation from the current user for why they are reporting this post. This is useful for users to provide evidence or explain why there is a problem with the post. NOTE: If reason is set to 'other', details are required.
  reason: string # The reason that this post is being reported. Must be one of: 'spam', 'not free (for sale/trade/borrow)', 'illegal item', 'not family-friendly', 'other', 'mislabeled: is a Want', 'mislabeled: is an Offer'. NOTE: If reason is set to 'other', the details parameter is required to be set.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/report") $auth.query)
  let req_body = {"details": $details, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Satisfy a post
#
# PUT /posts/{post_id}/satisfy
# operationId: satisfy_post
export def "posts-satisfy create" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/satisfy") $auth.query)
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

# Share a post
#
# POST /posts/{post_id}/share
# operationId: share_post
export def "posts-share create" [
  post_id: string
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
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/share") $auth.query)
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

# Unpromise an offer post
#
# PUT /posts/{post_id}/unpromise
# operationId: unpromise_post
export def "posts-unpromise create" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/unpromise") $auth.query)
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

# Withdraw a post
#
# PUT /posts/{post_id}/withdraw
# operationId: withdraw_post
export def "posts-withdraw create" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/posts/{post_id}/withdraw") $auth.query)
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

# List stories
#
# GET /stories
# operationId: get_stories
export def "stories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of stories to return. (default: 1)
  --per-page: int # The number of stories to return per page (must be >= 1 and <= 50). (default: 20)
  --sort-by: string # How to sort the stories that are returned. One of: date, distance, likes, views Setting sort_by to date will sort posts from newest to oldest. Setting sort_by to distance will sort posts from nearest to farthest. Setting sort_by to likes will sort posts with the most likes first. Setting sort_by to views will show the posts with the most views first. (default: date)
  --latitude: float # Find groups near the given latitude and longitude.
  --longitude: float # Find groups near the given latitude and longitude.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<stories: table<content: string, date: string, like_count: int, photos: list, share_url: string, story_id: string, title: string, user: record, user_liked: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "sort_by": $sort_by, "latitude": $latitude, "longitude": $longitude, "device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Submit a story
#
# POST /stories
# operationId: submit_story
export def "stories submit-story" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The content of the story.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this story.
  sharing: string # Must be set to one of the following two options: public, members When sharing is set to public, anyone will be able to view the story. When sharing is set to members, only other members will be able to view the story.
  title: string # The title of the story.
]: any -> record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stories" $auth.query)
  let req_body = {"content": $content, "device_pixel_ratio": $device_pixel_ratio, "photo_ids": $photo_ids, "sharing": $sharing, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Retrieve a story
#
# GET /stories/{story_id}
# operationId: get_story
export def "stories get" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($story_id | is-empty) { error make --unspanned { msg: "path parameter 'story_id' must be non-empty" } }
  let qp = [(serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({story_id: (encode-path-segment $story_id)} | format pattern "/stories/{story_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Like a story
#
# PUT /stories/{story_id}/like
# operationId: like_story
export def "stories-like update" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($story_id | is-empty) { error make --unspanned { msg: "path parameter 'story_id' must be non-empty" } }
  let qp = [(serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({story_id: (encode-path-segment $story_id)} | format pattern "/stories/{story_id}/like") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Unlike a story
#
# PUT /stories/{story_id}/unlike
# operationId: unlike_story
export def "stories-unlike update" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($story_id | is-empty) { error make --unspanned { msg: "path parameter 'story_id' must be non-empty" } }
  let qp = [(serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({story_id: (encode-path-segment $story_id)} | format pattern "/stories/{story_id}/unlike") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"device_pixel_ratio": $device_pixel_ratio} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Record story viewed
#
# POST /stories/{story_id}/viewed
# operationId: viewed_story
export def "stories-viewed create" [
  story_id: string
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
  if ($story_id | is-empty) { error make --unspanned { msg: "path parameter 'story_id' must be non-empty" } }
  let full_url = (build-url $base ({story_id: (encode-path-segment $story_id)} | format pattern "/stories/{story_id}/viewed") $auth.query)
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

# Retrieve current user
#
# GET /users/me
# operationId: get_current_user
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me" $auth.query)
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

# Update current user
#
# PUT /users/me
# operationId: update_current_user
export def "users-me update-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --about-me: string # A short bio a user has written about themselves to help other members get to know them better.
  --digest-photos: int # Whether or not to include photos in the digest emails. Set to 1 to enable photos and 0 to disable photos.
  --email-message-delay: string # How quickly new messages from other users are emailed to this user. One of: immediate, 30_minutes, 1_hour, 2_hours, 4_hours, 6_hours, 8_hours If set to anything other than immediate, the user will receive a digest email summarizing all of the new messages that they haven't viewed.
  --email-newsletters: string # If set to 1, the user will receive occasional email newsletters from trash nothing. To disable, set to 0.
  --email-post-reminders: int # If set to 1, the user will receive emails to remind them to handle their old posts. To disable, set to 0.
  --email-posts-frequency: string # How often new post email notifications are sent to the user. One of: weekly, twice_weekly, daily, 12_hours, 8_hours, 6_hours, 4_hours, 2_hours, hourly To turn off new post email notifications, set this to an empty string.
  --email-search-alerts: int # If set to 1, the user will receive emails when new posts that match one of their search alerts. To disable, set to 0.
  --firstname: string # The first name of the user.
  --last-listings-view: string # The UTC date and time when the user last viewed the newest posts on the All Posts page. (format: date-time)
  --lastname: string # The last name of the user.
  --notify-about-reposts: int # If set to 1, the user will be notified about reposts. This affects digests and search alerts. If set to 0, the user will not be notified about reposts. This does not affect the posts that are returned by the /posts endpoint which has an include_reposts option for this purpose. See the repost_count field of post objects for details about how reposts are identified.
  --old-password: string # The users current password. This is required when the user is changing their password.
  --password: string # A new password for the users' account. When setting a new password, the old_password parameter must be passed and set to the users' current password. NOTE: The password and old_password properties can NOT be used when the user property has_password is false. Instead, use the password reset endpoint to have a new password emailed to the user.
  --profile-image-source: string # The source of the users' profile image. The values this can be set to change dynamically based on the users' account. To get the values that can be used, use the source properties returned by the profile images endpoint.
  --public-name: int # Whether or not the users' first and last name will be visible to other users. Set to 1 to enable and 0 to disable.
  --public-post-sources: string # A comma separated list of the sources to show public posts from. Currently only 'trashnothing' is supported. If not passed, all sources will be enabled. If set to an empty string, no sources will be enabled which effectively disables public posts for the user so that the user will only see posts from the groups they are a member of. Setting to an empty string is only allowed if the user is a member of one or more groups.
  --show-all-group-posts: int # Set to 1 to show all group posts on the main posts page and in the digests. Set to 0 to only show group posts in the area defined by the users' location. Can only be set to 0 if the users' location is already set.
  --special-notices: int # Whether or not the user wants to receive special notice emails from the groups they are a member of. Special notices are admin posts that the group moderators choose to send out by email. Set to 1 to enable and 0 to disable.
]: any -> record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me" $auth.query)
  let req_body = {"about_me": $about_me, "digest_photos": $digest_photos, "email_message_delay": $email_message_delay, "email_newsletters": $email_newsletters, "email_post_reminders": $email_post_reminders, "email_posts_frequency": $email_posts_frequency, "email_search_alerts": $email_search_alerts, "firstname": $firstname, "last_listings_view": $last_listings_view, "lastname": $lastname, "notify_about_reposts": $notify_about_reposts, "old_password": $old_password, "password": $password, "profile_image_source": $profile_image_source, "public_name": $public_name, "public_post_sources": $public_post_sources, "show_all_group_posts": $show_all_group_posts, "special_notices": $special_notices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# List current users' email alerts
#
# GET /users/me/alerts
# operationId: get_alerts
export def "users-me-alerts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alert_id: string, last_sent: string, search: string, send_count: int, types: list<string>, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/alerts" $auth.query)
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

# Create an email alert
#
# PUT /users/me/alerts
# operationId: create_alert
export def "users-me-alerts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  search: string # When a post matches this search query, an email alert will be sent. Must have a length >= 2 and < 255 characters.
  types: string # A comma separated list of the post types that the alert should match against. The available post types are: offer, wanted
]: any -> record<alert_id: string, last_sent: string, search: string, send_count: int, types: list<string>, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/alerts" $auth.query)
  let req_body = {"search": $search, "types": $types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Delete an email alert
#
# DELETE /users/me/alerts/{alert_id}
# operationId: delete_alert
export def "users-me-alerts delete" [
  alert_id: string
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
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alert_id' must be non-empty" } }
  let full_url = (build-url $base ({alert_id: (encode-path-segment $alert_id)} | format pattern "/users/me/alerts/{alert_id}") $auth.query)
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

# Change email address
#
# POST /users/me/email
# operationId: change_email
export def "users-me-email create-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The new email address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/email" $auth.query)
  let req_body = {"address": $address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Set users' email address as not bouncing
#
# PUT /users/me/email/not-bouncing
# operationId: set_email_not_bouncing
export def "users-me-email-not-bouncing update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/email/not-bouncing" $auth.query)
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

# List current users' groups
#
# GET /users/me/groups
# operationId: get_current_user_groups
export def "users-me-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --membership: string # Set the membership parameter to only return certain groups. The options are: - **subscribed**: Only return groups the user is a member of. - **pending-questions**: Only return groups where the user needs to respond to a new member questionnaire. - **pending**: Only return groups where the user is waiting for their membership request to be approved (excludes groups which are pending-questions). If unset, all groups the user is a member of and pending membership on will be returned.
]: nothing -> table<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "membership" $membership "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/groups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"membership": $membership} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update location
#
# PUT /users/me/location
# operationId: update_location
export def "users-me-location update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  latitude: float
  longitude: float
  name: string # A name that describes the location specified by the given latitude and longitude (must be <= 128 characters).
  radius: float # A radius in meters that defines a circle around the point specified by latitude and longitude. Only posts within the area specified by this circle will be shown. If set to 0, effectively disables public posts for the user.
]: any -> record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/location" $auth.query)
  let req_body = {"latitude": $latitude, "longitude": $longitude, "name": $name, "radius": $radius} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# List current users' group notices
#
# GET /users/me/notices
# operationId: get_user_group_notices
export def "users-me-notices get-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-ids: string # A comma separated list of group IDs to return notices for. If unset, notices for all the users groups will be returned.
]: nothing -> table<content: string, date: string, group_id: string, notice_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_ids" $group_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/notices" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"group_ids": $group_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List current users' post locations
#
# GET /users/me/post-locations
# operationId: get_post_locations
export def "users-me-post-locations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<latitude: float, longitude: float, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/post-locations" $auth.query)
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

# Save a post location for the current user
#
# PUT /users/me/post-locations
# operationId: save_post_location
export def "users-me-post-locations create-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  latitude: float
  longitude: float
  name: string # A name that describes the location specified by the given latitude and longitude (must be >= 2 characters and <= 30 characters).
]: any -> table<latitude: float, longitude: float, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/post-locations" $auth.query)
  let req_body = {"latitude": $latitude, "longitude": $longitude, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $mp.body $insecure $raw $allow_errors $full [200]
}

# List current users' posts
#
# GET /users/me/posts
# operationId: get_current_user_posts
export def "users-me-posts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # How to sort the posts that are returned. One of: date, active, distance Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: date)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required.
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: )
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: )
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "outcomes" $outcomes "scalar") (serialize-qp "user_state" $user_state "scalar") (serialize-qp "include_reposts" $include_reposts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/posts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort_by": $sort_by, "types": $types, "sources": $sources, "group_ids": $group_ids, "per_page": $per_page, "page": $page, "device_pixel_ratio": $device_pixel_ratio, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "date_min": $date_min, "date_max": $date_max, "outcomes": $outcomes, "user_state": $user_state, "include_reposts": $include_reposts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search current users' posts
#
# GET /users/me/posts/search
# operationId: search_current_user_posts
export def "users-me-posts-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find posts.
  --sort-by: string # How to sort the posts that are returned. One of: relevance, date, active, distance Relevance sorting will sort the posts that best match the search query first. Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: relevance)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required.
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: )
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: )
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "outcomes" $outcomes "scalar") (serialize-qp "user_state" $user_state "scalar") (serialize-qp "include_reposts" $include_reposts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/posts/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "sort_by": $sort_by, "types": $types, "sources": $sources, "group_ids": $group_ids, "per_page": $per_page, "page": $page, "device_pixel_ratio": $device_pixel_ratio, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "date_min": $date_min, "date_max": $date_max, "outcomes": $outcomes, "user_state": $user_state, "include_reposts": $include_reposts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Set a profile image
#
# POST /users/me/profile-image
# operationId: set_profile_image
export def "users-me-profile-image update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --crop: string # If the photo needs to be cropped, a JSON encoded object with the crop arguments can be passed. The supported crop arguments are below. All arguments except rotate are required. - **original_width**: Original width of the photo before being cropped or rotated (in pixels). - **original_height**: Original height of the photo before being cropped or rotated (in pixels). - **x**: The x-coordinate of the top left corner of the cropped area. - **y**: The y-coordinate of the top left corner of the cropped area. - **size**: The size of the square cropped area. - **rotate**: (optional) The number of degrees to rotate the image before cropping. Currently only 90, 180 and 270 are supported which correspond to rotate left, rotate upside down and rotate right.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --photo: string # Photo to upload. (format: binary)
  --photo-id: string # Photo to use (if already uploaded).
  --set-default: int # Whether or not to set the photo as the users' default profile image. Set to 1 to enable and 0 to disable. (default: 1)
]: any -> record<photo: record<photo_id: string, thumbnail: record<height: int, url: string, width: int>>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/profile-image" $auth.query)
  let req_body = {"crop": $crop, "device_pixel_ratio": $device_pixel_ratio, "photo": $photo, "photo_id": $photo_id, "set_default": $set_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["photo"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# List current users' profile images
#
# GET /users/me/profile-images
# operationId: get_profile_images
export def "users-me-profile-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<image: string, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/profile-images" $auth.query)
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

# Resend account verification email
#
# POST /users/me/resend-verification
# operationId: resend_account_verification_email
export def "users-me-resend-verification resend-account-email" [
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
  let full_url = (build-url $base "/users/me/resend-verification" $auth.query)
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

# Send password reset email
#
# POST /users/me/reset-password
# operationId: send_password_reset_email
export def "users-me-reset-password send-email" [
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
  let full_url = (build-url $base "/users/me/reset-password" $auth.query)
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

# Report a user
#
# POST /users/report
# operationId: report_user
export def "users-report create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string # The ID of the group to report the user to. This may be disregarded in cases where user_email is set and can be used to automatically identify which group the user should be reported to (because some email addresses are specific to certain groups).
  message: string # The body of the message.
  --subject: string # The subject of the message.
  --user-email: string # The email of the user to report. Often users only know to identify other users by their email addresses so allowing users to enter an email address can be easier in certain cases.
  --user-id: string # The ID of the user to report. One of user_id or user_email must be passed but only user_id will be used if both are passed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/report" $auth.query)
  let req_body = {"group_id": $group_id, "message": $message, "subject": $subject, "user_email": $user_email, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Retrieve a user
#
# GET /users/{user_id}
# operationId: get_user
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $auth.query)
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

# Retrieve user display info
#
# GET /users/{user_id}/display
# operationId: get_user_and_related_data
export def "users-display get-and-related-data" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<feedback: table<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, offer_count: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, wanted_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/display") $auth.query)
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

# Remove feedback on a user
#
# DELETE /users/{user_id}/feedback
# operationId: remove_user_feedback
export def "users-feedback delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/feedback") $auth.query)
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

# Submit feedback on a user
#
# POST /users/{user_id}/feedback
# operationId: submit_user_feedback
export def "users-feedback submit" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # For positive feedback, category should not be set. For negative feedback, category should be set to one of: NO_SHOW, UNRESPONSIVE, LATE_OR_TOO_EARLY, ITEM_NOT_AS_DESCRIBED, BROKEN_PROMISE, RUDE, RESELLER, SELLING, UNWANTED_MESSAGES, COMMUNICATION, OTHER Below are descriptions for each of these categories: **NO_SHOW** - The user did not show up when they said they would. **UNRESPONSIVE** - The user failed to respond when a response was expected. **LATE_OR_TOO_EARLY** - The user showed up later than they said they would (or too early). **ITEM_NOT_AS_DESCRIBED** - The user gave away an item that had a misleading on incomplete description. **BROKEN_PROMISE** - The user broke a promise. **RUDE** - The user was rude or impolite. **RESELLER** - The user is obtaining free items to sell on other sites without disclosing their intent to resell. **SELLING** - The user is selling items on trash nothing. **UNWANTED_MESSAGES** - The user is sending off-topic or unrelated messages. **COMMUNICATION** - The users' communication is unclear, confusing or bad. **OTHER** - This category is for anything that does not fit in any of the above categories.
  --content: string # A comment written by the current user about the user they are leaving feedback on. This is optional for positive feedback but is required for negative feedback.
  positive: int # If set to 1, the feedback is positive. If set to 0, the feedback is negative.
]: any -> record<feedback: record<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/feedback") $auth.query)
  let req_body = {"category": $category, "content": $content, "positive": $positive} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# List posts by a user
#
# GET /users/{user_id}/posts
# operationId: get_user_posts
export def "users-posts get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # How to sort the posts that are returned. One of: date, active, distance Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: date)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or all the open archive groups the requested user has posted to if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required.
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: )
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "outcomes" $outcomes "scalar") (serialize-qp "include_reposts" $include_reposts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/posts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort_by": $sort_by, "types": $types, "sources": $sources, "group_ids": $group_ids, "per_page": $per_page, "page": $page, "device_pixel_ratio": $device_pixel_ratio, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "date_min": $date_min, "date_max": $date_max, "outcomes": $outcomes, "include_reposts": $include_reposts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search posts by a user
#
# GET /users/{user_id}/posts/search
# operationId: search_user_posts
export def "users-posts-search list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find posts.
  --sort-by: string # How to sort the posts that are returned. One of: relevance, date, active, distance Relevance sorting will sort the posts that best match the search query first. Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: relevance)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or all the open archive groups the requested user has posted to if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required.
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: )
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "group_ids" $group_ids "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "device_pixel_ratio" $device_pixel_ratio "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "date_min" $date_min "scalar") (serialize-qp "date_max" $date_max "scalar") (serialize-qp "outcomes" $outcomes "scalar") (serialize-qp "include_reposts" $include_reposts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/posts/search") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "sort_by": $sort_by, "types": $types, "sources": $sources, "group_ids": $group_ids, "per_page": $per_page, "page": $page, "device_pixel_ratio": $device_pixel_ratio, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "date_min": $date_min, "date_max": $date_max, "outcomes": $outcomes, "include_reposts": $include_reposts} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a users' profile image
#
# GET /users/{user_id}/profile-image
# operationId: get_profile_image_file
export def "users-profile-image get-file" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: string # A default image URL to use when the user has no profile image. Or to use one of the Gravatar default images, you can set default to any one of (404, mm, identicon, monsterid, wavatar, retro, blank). To learn how the Gravatar default images options work, see the Default Image section on the page at: https://en.gravatar.com/site/implement/images/
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "default" $default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/profile-image") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"default": $default} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [302]
}
