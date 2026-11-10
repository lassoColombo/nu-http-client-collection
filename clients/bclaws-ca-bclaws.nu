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

def base-url-completer [] { ["http://www.bclaws.ca/civix" "https://www.bclaws.ca/civix"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def aspect-id-completer [] { ["arch_oic" "bcgaz1" "bcgaz2" "complete" "corpreg" "ecb" "hscr" "oic" "psl"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-content-aspect-id" "get-content-aspect-id-civix-document-id" "get-document-id-aspect-id-civix-index-id-civix-document-id" "get-document-id-aspect-id-civix-index-id-civix-document-id-search-search-string" "get-document-id-aspect-id-civix-index-id-civix-document-id-xml" "get-document-id-aspect-id-civix-index-id-civix-document-id-xml-search-search-string" "get-search-aspect-id-fullsearch" "commands"] | sort) } | get name | first)
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

# Describes the documents and directories available within a specific 'aspect' (content group) of the BCLaws library
#
# GET /content/{aspectId}
export def "get-content-aspect-id" [
  aspect_id: string@aspect-id-completer
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
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "get-content-aspect-id-civix-document-id" [
  aspect_id: string@aspect-id-completer
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
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "get-document-id-aspect-id-civix-index-id-civix-document-id" [
  aspect_id: string@aspect-id-completer
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
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "get-document-id-aspect-id-civix-index-id-civix-document-id-search-search-string" [
  aspect_id: string@aspect-id-completer
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
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "get-document-id-aspect-id-civix-index-id-civix-document-id-xml" [
  aspect_id: string@aspect-id-completer
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
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "get-document-id-aspect-id-civix-index-id-civix-document-id-xml-search-search-string" [
  aspect_id: string@aspect-id-completer
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
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
export def "get-search-aspect-id-fullsearch" [
  aspect_id: string@aspect-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # query term (required, default: water)
  --s: string # first hit (start index) (required, default: 0)
  --e: int # last hit (end index) (required, default: 20)
  --n-frag: int # number of fragment snippets to return (< 10) (required, default: 5)
  --l-frag: int # length of fragment snippets (< 200) (required, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($aspect_id | is-empty) { error make --unspanned { msg: "path parameter 'aspectId' must be non-empty" } }
  let q = ($q | default "water")
  let s = ($s | default "0")
  let e = ($e | default 20)
  let n_frag = ($n_frag | default 5)
  let l_frag = ($l_frag | default 100)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "s" $s "scalar") (serialize-qp "e" $e "scalar") (serialize-qp "nFrag" $n_frag "scalar") (serialize-qp "lFrag" $l_frag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aspect_id: (encode-path-segment $aspect_id)} | format pattern "/search/{aspect_id}/fullsearch") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
