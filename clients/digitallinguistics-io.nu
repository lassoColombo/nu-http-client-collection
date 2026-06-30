# Auto-generated client for DLx v0.3.1
# Source: https://api.apis.guru/v2/specs/digitallinguistics.io/0.3.1/swagger.json
# Auth: --token flag or $env.DLX_TOKEN

const BASE_URL = "https://api.digitallinguistics.io/v0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o DLX_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.digitallinguistics.io/v0"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "languages list" } } | get name | first)
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

# Get all Languages
#
# GET /languages
# operationId: getLanguages
export def "languages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Setting the `deleted` option to `true` will return results that have been marked for deletion, but not yet deleted from the database. Otherwise requests for a resource marked for deletion will return a 410 error. (default: false)
  --public: string # Set this parameter to `true` to include all publicly-accessible resources, not just those that the user is listed as an Owner, Contributor, or Viewer for. (default: false)
  --continuation: string # The `dlx-continuation` header is used to send a continuation token with the request, when retrieving the next page of results.
  --if-modified-since: string # The `If-Modified-Since` header is used to retrieve only results modified since a given time. The value of this header must be a valid date string.
  --max-item-count: string # The `dlx-max-item-count` header is used to limit the number of results to a certain amount at a time (by default all results will be returned). If there are more results to be returned, a continuation token will also be sent in the `dlx-continuation` header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleted" $deleted "scalar") (serialize-qp "public" $public "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/languages" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"continuation": $continuation, "ifModifiedSince": $if_modified_since, "maxItemCount": $max_item_count} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deleted": $deleted, "public": $public} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a new Language
#
# POST /languages
# operationId: addLanguage
export def "languages create" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages" $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Upsert (create or replace) a Language
#
# PUT /languages
# operationId: upsertLanguage
export def "languages update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Language by ID
#
# DELETE /languages/{languageID}
# operationId: deleteLanguage
export def "languages delete" [
  language_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id)} | format pattern "/languages/{language_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a Language by ID
#
# GET /languages/{languageID}
# operationId: getLanguage
export def "languages get" [
  language_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Setting the `deleted` option to `true` will return results that have been marked for deletion, but not yet deleted from the database. Otherwise requests for a resource marked for deletion will return a 410 error. (default: false)
  --if-none-match: string # If `If-None-Match` header is used with GET requests to check whether you already have the most up-to-date version of the resource, and therefore do not need the resource sent again. The value of the `If-None-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to reduce bandwidth.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  let qp = [(serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id)} | format pattern "/languages/{language_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifNoneMatch": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deleted": $deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Perform a partial update on a Language
#
# PATCH /languages/{languageID}
# operationId: updateLanguage
export def "languages update-by-language-id" [
  language_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id)} | format pattern "/languages/{language_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get all Lexemes for a Language
#
# GET /languages/{languageID}/lexemes
# operationId: getLexemesByLanguage
export def "languages-lexemes list" [
  language_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Setting the `deleted` option to `true` will return results that have been marked for deletion, but not yet deleted from the database. Otherwise requests for a resource marked for deletion will return a 410 error. (default: false)
  --public: string # Set this parameter to `true` to include all publicly-accessible resources, not just those that the user is listed as an Owner, Contributor, or Viewer for. (default: false)
  --continuation: string # The `dlx-continuation` header is used to send a continuation token with the request, when retrieving the next page of results.
  --if-modified-since: string # The `If-Modified-Since` header is used to retrieve only results modified since a given time. The value of this header must be a valid date string.
  --max-item-count: string # The `dlx-max-item-count` header is used to limit the number of results to a certain amount at a time (by default all results will be returned). If there are more results to be returned, a continuation token will also be sent in the `dlx-continuation` header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  let qp = [(serialize-qp "deleted" $deleted "scalar") (serialize-qp "public" $public "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id)} | format pattern "/languages/{language_id}/lexemes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"continuation": $continuation, "ifModifiedSince": $if_modified_since, "maxItemCount": $max_item_count} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deleted": $deleted, "public": $public} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a new Lexeme to a Language
#
# POST /languages/{languageID}/lexemes
# operationId: addLexemeByLanguage
export def "languages-lexemes create" [
  language_id: string
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
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id)} | format pattern "/languages/{language_id}/lexemes") $auth.query)
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

# Upsert (add or replace) a Lexeme
#
# PUT /languages/{languageID}/lexemes
# operationId: upsertLexemeByLanguage
export def "languages-lexemes update-by-language-id" [
  language_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id)} | format pattern "/languages/{language_id}/lexemes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# Delete a Lexeme by ID
#
# DELETE /languages/{languageID}/lexemes/{lexemeID}
# operationId: deleteLexemeByLanguage
export def "languages-lexemes delete" [
  language_id: string
  lexeme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  if ($lexeme_id | is-empty) { error make --unspanned { msg: "path parameter 'lexemeID' must be non-empty" } }
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id), lexeme_id: (encode-path-segment $lexeme_id)} | format pattern "/languages/{language_id}/lexemes/{lexeme_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a Lexeme by ID
#
# GET /languages/{languageID}/lexemes/{lexemeID}
# operationId: getLexemeByLanguage
export def "languages-lexemes get" [
  language_id: string
  lexeme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Setting the `deleted` option to `true` will return results that have been marked for deletion, but not yet deleted from the database. Otherwise requests for a resource marked for deletion will return a 410 error. (default: false)
  --if-none-match: string # If `If-None-Match` header is used with GET requests to check whether you already have the most up-to-date version of the resource, and therefore do not need the resource sent again. The value of the `If-None-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to reduce bandwidth.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  if ($lexeme_id | is-empty) { error make --unspanned { msg: "path parameter 'lexemeID' must be non-empty" } }
  let qp = [(serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id), lexeme_id: (encode-path-segment $lexeme_id)} | format pattern "/languages/{language_id}/lexemes/{lexeme_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifNoneMatch": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deleted": $deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Perform a partial update on a Lexeme
#
# PATCH /languages/{languageID}/lexemes/{lexemeID}
# operationId: updateLexemeByLanguage
export def "languages-lexemes update-by-language-id-lexeme-id" [
  language_id: string
  lexeme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageID' must be non-empty" } }
  if ($lexeme_id | is-empty) { error make --unspanned { msg: "path parameter 'lexemeID' must be non-empty" } }
  let full_url = (build-url $base ({language_id: (encode-path-segment $language_id), lexeme_id: (encode-path-segment $lexeme_id)} | format pattern "/languages/{language_id}/lexemes/{lexeme_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}

# Get all Lexemes
#
# GET /lexemes
# operationId: getLexemes
export def "lexemes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Setting the `deleted` option to `true` will return results that have been marked for deletion, but not yet deleted from the database. Otherwise requests for a resource marked for deletion will return a 410 error. (default: false)
  --language-id: string # The ID of the Language to perform the operation on (allows empty value)
  --public: string # Set this parameter to `true` to include all publicly-accessible resources, not just those that the user is listed as an Owner, Contributor, or Viewer for. (default: false)
  --continuation: string # The `dlx-continuation` header is used to send a continuation token with the request, when retrieving the next page of results.
  --if-modified-since: string # The `If-Modified-Since` header is used to retrieve only results modified since a given time. The value of this header must be a valid date string.
  --max-item-count: string # The `dlx-max-item-count` header is used to limit the number of results to a certain amount at a time (by default all results will be returned). If there are more results to be returned, a continuation token will also be sent in the `dlx-continuation` header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleted" $deleted "scalar") (serialize-qp "languageID" $language_id "scalar") (serialize-qp "public" $public "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lexemes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"continuation": $continuation, "ifModifiedSince": $if_modified_since, "maxItemCount": $max_item_count} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deleted": $deleted, "languageID": $language_id, "public": $public} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a new Lexeme
#
# POST /lexemes
# operationId: addLexeme
export def "lexemes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language-id: string # The ID of the Language to perform the operation on (allows empty value)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languageID" $language_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lexemes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"languageID": $language_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Upsert (add or replace) a Lexeme
#
# PUT /lexemes
# operationId: upsertLexeme
export def "lexemes update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language-id: string # The ID of the Language to perform the operation on (allows empty value)
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languageID" $language_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lexemes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"languageID": $language_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# Delete a Lexeme by ID
#
# DELETE /lexemes/{lexemeID}
# operationId: deleteLexeme
export def "lexemes delete" [
  lexeme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lexeme_id | is-empty) { error make --unspanned { msg: "path parameter 'lexemeID' must be non-empty" } }
  let full_url = (build-url $base ({lexeme_id: (encode-path-segment $lexeme_id)} | format pattern "/lexemes/{lexeme_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a Lexeme by ID
#
# GET /lexemes/{lexemeID}
# operationId: getLexeme
export def "lexemes get" [
  lexeme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Setting the `deleted` option to `true` will return results that have been marked for deletion, but not yet deleted from the database. Otherwise requests for a resource marked for deletion will return a 410 error. (default: false)
  --if-none-match: string # If `If-None-Match` header is used with GET requests to check whether you already have the most up-to-date version of the resource, and therefore do not need the resource sent again. The value of the `If-None-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to reduce bandwidth.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lexeme_id | is-empty) { error make --unspanned { msg: "path parameter 'lexemeID' must be non-empty" } }
  let qp = [(serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lexeme_id: (encode-path-segment $lexeme_id)} | format pattern "/lexemes/{lexeme_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifNoneMatch": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"deleted": $deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Perform a partial update on a Lexeme
#
# PATCH /lexemes/{lexemeID}
# operationId: updateLexeme
export def "lexemes update-by-lexeme-id" [
  lexeme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The `If-Match` header is used with PUT and DELETE requests to check whether you have the most up-to-date version of the resource before updating or deleting it. The value of the `If-Match` header is the ETag (`_etag`) property of the resource. It is recommended that your application use this header whenever possible to avoid data conflicts.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lexeme_id | is-empty) { error make --unspanned { msg: "path parameter 'lexemeID' must be non-empty" } }
  let full_url = (build-url $base ({lexeme_id: (encode-path-segment $lexeme_id)} | format pattern "/lexemes/{lexeme_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ifMatch": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}
