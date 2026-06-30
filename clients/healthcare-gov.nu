# Auto-generated client for Healthcare v1.0.0
# Source: https://api.apis.guru/v2/specs/healthcare.gov/1.0.0/openapi.json
# Auth: --token flag or $env.HEALTHCARE_TOKEN

const BASE_URL = "https://www.healthcare.gov"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o HEALTHCARE_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.healthcare.gov"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "articlesmedia-type-extension get" } } | get name | first)
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

# Returns pages content.
#
# GET /api/articles{mediaTypeExtension}
export def "articlesmedia-type-extension get" [
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
]: nothing -> record<articles: table<bite: string, categories: list, content: string, date: string, excerpt: string, featured: bool, id: string, lang: string, layout: string, meta_description: string, meta_title: string, path: string, published: bool, related: list, seo_keywords: string, sort: float, tags: list, title: string, title_short: string, topics: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/api/articles{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /api/blog{mediaTypeExtension}
export def "blogmedia-type-extension get" [
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
]: nothing -> record<blog: list<list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/api/blog{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /api/glossary{mediaTypeExtension}
export def "glossarymedia-type-extension get" [
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
]: nothing -> record<glossary: table<categories: list, content: string, date: string, excerpt: string, id: string, lang: string, layout: string, path: string, published: bool, sort: float, tags: list, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/api/glossary{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /api/questions{mediaTypeExtension}
export def "questionsmedia-type-extension get" [
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
]: nothing -> record<questions: table<categories: list, content: string, date: string, excerpt: string, id: string, lang: string, path: string, published: bool, sort: float, tags: list, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/api/questions{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /api/states{mediaTypeExtension}
export def "statesmedia-type-extension get" [
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
]: nothing -> record<states: list<list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/api/states{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /api/topics{mediaTypeExtension}
export def "topicsmedia-type-extension get" [
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
]: nothing -> record<topics: table<articleorder: list, categories: list, content: string, date: string, excerpt: string, id: string, lang: string, layout: string, meta_description: string, meta_title: string, order: float, path: string, published: bool, sort: float, tags: list, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/api/topics{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /blog/{pageName}{mediaTypeExtension}
export def "blog get" [
  page_name: string
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
]: nothing -> record<categories: list<list<string>>, content: string, date: string, excerpt: string, id: string, lang: string, layout: string, meta_description: string, meta_title: string, path: string, published: bool, seo_keywords: string, sort: float, tags: list<list<any>>, title: string, topics: list<list<string>>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/blog/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "application/html"
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

# Returns pages content.
#
# GET /es/blog/{pageName}{mediaTypeExtension}
export def "es-blog get" [
  page_name: string
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
]: nothing -> record<categories: list<list<string>>, content: string, date: string, excerpt: string, id: string, lang: string, layout: string, meta_description: string, meta_title: string, path: string, published: bool, seo_keywords: string, sort: float, tags: list<list<any>>, title: string, topics: list<list<string>>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/es/blog/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "application/html"
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

# Returns pages content.
#
# GET /es/glossary/{pageName}{mediaTypeExtension}
export def "es-glossary get" [
  page_name: string
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
]: nothing -> record<categories: list<string>, content: string, date: string, excerpt: string, id: string, lang: string, layout: string, path: string, published: bool, sort: float, tags: list<string>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/es/glossary/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "application/html"
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

# Returns pages content.
#
# GET /es/question/{pageName}{mediaTypeExtension}
export def "es-question get" [
  page_name: string
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
]: nothing -> record<categories: list<string>, content: string, date: string, excerpt: string, id: string, lang: string, path: string, published: bool, sort: float, tags: list<string>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/es/question/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /es/{pageName}{mediaTypeExtension}
export def "es get-by-page-name-media-type-extension" [
  page_name: string
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
]: nothing -> record<categories: list<list<any>>, content: string, date: string, excerpt: string, experience: string, id: string, lang: string, layout: string, path: string, published: bool, sort: float, tags: list<list<any>>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/es/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "application/html"
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

# Returns pages content.
#
# GET /es/{stateName}{mediaTypeExtension}
export def "es get-by-state-name-media-type-extension" [
  state_name: string
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
]: nothing -> record<categories: list<list<any>>, content: string, date: string, excerpt: string, id: string, lang: string, path: string, sort: float, stateurl: string, tags: list<list<string>>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($state_name | is-empty) { error make --unspanned { msg: "path parameter 'stateName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({state_name: (encode-path-segment $state_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/es/{state_name}{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /glossary/{pageName}{mediaTypeExtension}
export def "glossary get" [
  page_name: string
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
]: nothing -> record<categories: list<string>, content: string, date: string, excerpt: string, id: string, lang: string, layout: string, path: string, published: bool, sort: float, tags: list<string>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/glossary/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "application/html"
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

# Returns pages content.
#
# GET /question/{pageName}{mediaTypeExtension}
export def "question get" [
  page_name: string
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
]: nothing -> record<categories: list<string>, content: string, date: string, excerpt: string, id: string, lang: string, path: string, published: bool, sort: float, tags: list<string>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/question/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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

# Returns pages content.
#
# GET /{pageName}{mediaTypeExtension}
export def "api get-by-page-name-media-type-extension" [
  page_name: string
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
]: nothing -> record<categories: list<list<any>>, content: string, date: string, excerpt: string, experience: string, id: string, lang: string, layout: string, path: string, published: bool, sort: float, tags: list<list<any>>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($page_name | is-empty) { error make --unspanned { msg: "path parameter 'pageName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({page_name: (encode-path-segment $page_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/{page_name}{media_type_extension}") $auth.query)
  let accept_val = "application/html"
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

# Returns pages content.
#
# GET /{stateName}{mediaTypeExtension}
export def "api get-by-state-name-media-type-extension" [
  state_name: string
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
]: nothing -> record<categories: list<list<any>>, content: string, date: string, excerpt: string, id: string, lang: string, path: string, sort: float, stateurl: string, tags: list<list<string>>, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($state_name | is-empty) { error make --unspanned { msg: "path parameter 'stateName' must be non-empty" } }
  if ($media_type_extension | is-empty) { error make --unspanned { msg: "path parameter 'mediaTypeExtension' must be non-empty" } }
  let full_url = (build-url $base ({state_name: (encode-path-segment $state_name), media_type_extension: (encode-path-segment $media_type_extension)} | format pattern "/{state_name}{media_type_extension}") $auth.query)
  let accept_val = "*/*"
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
