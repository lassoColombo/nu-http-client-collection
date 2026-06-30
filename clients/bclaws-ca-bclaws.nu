# Auto-generated client for BC Laws v1.0.0
# Source: https://api.apis.guru/v2/specs/bclaws.ca/bclaws/1.0.0/openapi.json
# Auth: --token flag or $env.BC_LAWS_TOKEN

const BASE_URL = "http://www.bclaws.ca/civix"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BC_LAWS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://www.bclaws.ca/civix" "https://www.bclaws.ca/civix"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "content list" } } | get name | first)
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

# Describes the documents and directories available within a specific 'aspect' (content group) of the BCLaws library
#
# GET /content/{aspectId}
export def "content list" [
  aspect_id: string
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
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id)} | format pattern "/content/{aspect_id}") $auth.query)
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

# Lists the metadata available for the specified index or directory from the BCLaws legislative respository
#
# GET /content/{aspectId}/{civixDocumentId}
export def "content get" [
  aspect_id: string
  civix_document_id: string
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
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  if ($civix_document_id | is-empty) { error make --unspanned { msg: "path parameter 'civixDocumentId' must be non-empty" } }
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id), civix_document_id: (encode-path-segment $civix_document_id)} | format pattern "/content/{aspect_id}/{civix_document_id}") $auth.query)
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

# Retrieves a specific document from the BCLaws legislative repository (HTML format)
#
# GET /document/id/{aspectId}/{civixIndexId}/{civixDocumentId}
export def "document-id get" [
  aspect_id: string
  civix_index_id: string
  civix_document_id: string
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
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  if ($civix_index_id | is-empty) { error make --unspanned { msg: "path parameter 'civixIndexId' must be non-empty" } }
  if ($civix_document_id | is-empty) { error make --unspanned { msg: "path parameter 'civixDocumentId' must be non-empty" } }
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id), civix_index_id: (encode-path-segment $civix_index_id), civix_document_id: (encode-path-segment $civix_document_id)} | format pattern "/document/id/{aspect_id}/{civix_index_id}/{civix_document_id}") $auth.query)
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

# Retrieves a specific document from the BCLaws legislative repository with search text highlighted (HTML format)
#
# GET /document/id/{aspectId}/{civixIndexId}/{civixDocumentId}/search/{searchString}
export def "document-id-search get" [
  aspect_id: string
  civix_index_id: string
  civix_document_id: string
  search_string: string
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
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  if ($civix_index_id | is-empty) { error make --unspanned { msg: "path parameter 'civixIndexId' must be non-empty" } }
  if ($civix_document_id | is-empty) { error make --unspanned { msg: "path parameter 'civixDocumentId' must be non-empty" } }
  if ($search_string | is-empty) { error make --unspanned { msg: "path parameter 'searchString' must be non-empty" } }
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id), civix_index_id: (encode-path-segment $civix_index_id), civix_document_id: (encode-path-segment $civix_document_id), search_string: (encode-path-segment $search_string)} | format pattern "/document/id/{aspect_id}/{civix_index_id}/{civix_document_id}/search/{search_string}") $auth.query)
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

# Retrieves a specific document from the BCLaws legislative repository (XML format)
#
# GET /document/id/{aspectId}/{civixIndexId}/{civixDocumentId}/xml
export def "document-id-xml get" [
  aspect_id: string
  civix_index_id: string
  civix_document_id: string
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
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  if ($civix_index_id | is-empty) { error make --unspanned { msg: "path parameter 'civixIndexId' must be non-empty" } }
  if ($civix_document_id | is-empty) { error make --unspanned { msg: "path parameter 'civixDocumentId' must be non-empty" } }
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id), civix_index_id: (encode-path-segment $civix_index_id), civix_document_id: (encode-path-segment $civix_document_id)} | format pattern "/document/id/{aspect_id}/{civix_index_id}/{civix_document_id}/xml") $auth.query)
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

# Retrieves a specific document from the BCLaws legislative repository with search text highlighted (XML format)
#
# GET /document/id/{aspectId}/{civixIndexId}/{civixDocumentId}/xml/search/{searchString}
export def "document-id-xml-search get" [
  aspect_id: string
  civix_index_id: string
  civix_document_id: string
  search_string: string
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
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  if ($civix_index_id | is-empty) { error make --unspanned { msg: "path parameter 'civixIndexId' must be non-empty" } }
  if ($civix_document_id | is-empty) { error make --unspanned { msg: "path parameter 'civixDocumentId' must be non-empty" } }
  if ($search_string | is-empty) { error make --unspanned { msg: "path parameter 'searchString' must be non-empty" } }
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id), civix_index_id: (encode-path-segment $civix_index_id), civix_document_id: (encode-path-segment $civix_document_id), search_string: (encode-path-segment $search_string)} | format pattern "/document/id/{aspect_id}/{civix_index_id}/{civix_document_id}/xml/search/{search_string}") $auth.query)
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

# A listing of metadata available for the specified aspect and search term from the BCLaws legislative repository
#
# GET /search/{aspectId}/fullsearch
export def "search-fullsearch get" [
  aspect_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # query term (default: water)
  --s: string # first hit (start index) (default: 0)
  --e: int # last hit (end index) (default: 20)
  --n-frag: int # number of fragment snippets to return (< 10) (default: 5)
  --l-frag: int # length of fragment snippets (< 200) (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "s" $s "scalar") (serialize-qp "e" $e "scalar") (serialize-qp "nFrag" $n_frag "scalar") (serialize-qp "lFrag" $l_frag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id)} | format pattern "/search/{aspect_id}/fullsearch") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "s": $s, "e": $e, "nFrag": $n_frag, "lFrag": $l_frag} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
