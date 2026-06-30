# Auto-generated client for Aggregators API Service v0.6-99cfdac
# Source: https://api.apis.guru/v2/specs/zeno.fm/0.6-99cfdac/openapi.json
# Auth: --token flag or $env.AGGREGATORS_API_SERVICE_TOKEN

const BASE_URL = "https://api.zeno.fm"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AGGREGATORS_API_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-zeno-api-key" => { {scheme: $scheme, headers: {x-zeno-api-key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.zeno.fm"] }
def auth-scheme-completer [] { ["x-zeno-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "podcasts-categories get" } } | get name | first)
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

# Get the list of Categories that can be used to filter podcasts in the search podcasts request
#
# GET /api/v2/podcasts/categories
# operationId: getPodcastCategories
export def "podcasts-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, parent: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/categories" $auth.query)
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

# Get the list of Countries that can be used to filter podcasts in the search podcasts request
#
# GET /api/v2/podcasts/countries
# operationId: getPodcastCountries
export def "podcasts-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<iso: string, iso3: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/countries" $auth.query)
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

# Create podcast
#
# POST /api/v2/podcasts/create
# operationId: createPodcast
# --podcast shape: {author?: string, block?: bool, categories: list<string>, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list<string>, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
export def "podcasts-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_logo: string # format: binary
  podcast: record # Podcast model — shape: {author?: string, block?: bool, categories: list<string>, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list<string>, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
]: any -> record<author: string, block: bool, categories: list<string>, copyright: string, country: string, description: string, explicit: bool, image: string, key: string, keywords: list<string>, language: string, link: string, ownerEmail: string, ownerName: string, showType: string, subtitle: string, summary: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/create" $auth.query)
  let req_body = {"file_logo": $file_logo, "podcast": $podcast} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file_logo"] $dry_run)
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

# Get the list of Languages that can be used to filter podcasts in the search podcasts request
#
# GET /api/v2/podcasts/languages
# operationId: getPodcastLanguages
export def "podcasts-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/languages" $auth.query)
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

# Search podcasts
#
# POST /api/v2/podcasts/search
# operationId: searchPodcasts
# --filters shape: {category?: list<string>, country?: list<string>, language?: list<string>, podcastType?: "podcasts"|"shows"}
export def "podcasts-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # Filters for podcast search — shape: {category?: list<string>, country?: list<string>, language?: list<string>, podcastType?: "podcasts"|"shows"}
  --hits-per-page: int # format: int32, default: 10
  --page: int # format: int32, default: 1
  --query: string
]: any -> record<hits: table<author: string, block: bool, categories: list, copyright: string, country: string, description: string, explicit: bool, image: string, key: string, keywords: list, language: string, link: string, ownerEmail: string, ownerName: string, showType: string, subtitle: string, summary: string, title: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/search" $auth.query)
  let req_body = {"filters": $filters, "hitsPerPage": $hits_per_page, "page": $page, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
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

# Delete podcast
#
# DELETE /api/v2/podcasts/{podcastKey}
# operationId: deletePodcast
export def "podcasts delete" [
  podcast_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key)} | format pattern "/api/v2/podcasts/{podcast_key}") $auth.query)
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

# Get podcast
#
# GET /api/v2/podcasts/{podcastKey}
# operationId: getPodcast
export def "podcasts get" [
  podcast_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: string, block: bool, categories: list<string>, copyright: string, country: string, description: string, explicit: bool, image: string, key: string, keywords: list<string>, language: string, link: string, ownerEmail: string, ownerName: string, showType: string, subtitle: string, summary: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key)} | format pattern "/api/v2/podcasts/{podcast_key}") $auth.query)
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

# Update podcast
#
# PUT /api/v2/podcasts/{podcastKey}
# operationId: updatePodcast
# --podcast shape: {author?: string, block?: bool, categories: list<string>, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list<string>, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
export def "podcasts update" [
  podcast_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-logo: string # format: binary
  podcast: record # Podcast model — shape: {author?: string, block?: bool, categories: list<string>, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list<string>, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
]: any -> record<author: string, block: bool, categories: list<string>, copyright: string, country: string, description: string, explicit: bool, image: string, key: string, keywords: list<string>, language: string, link: string, ownerEmail: string, ownerName: string, showType: string, subtitle: string, summary: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key)} | format pattern "/api/v2/podcasts/{podcast_key}") $auth.query)
  let req_body = {"file_logo": $file_logo, "podcast": $podcast} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file_logo"] $dry_run)
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

# Get podcast episodes
#
# GET /api/v2/podcasts/{podcastKey}/episodes
# operationId: getPodcastEpisodes
export def "podcasts-episodes list" [
  podcast_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # default: 10
  --offset: string # default: 0
]: nothing -> record<items: table<author: string, block: bool, description: string, duration: int, episode: int, episodeType: string, explicit: bool, fileUrl: string, image: string, key: string, link: string, publishDate: string, season: int, size: int, subtitle: string, summary: string, tags: list, title: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key)} | format pattern "/api/v2/podcasts/{podcast_key}/episodes") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create podcast episode
#
# POST /api/v2/podcasts/{podcastKey}/episodes/create
# operationId: createPodcastEpisode
# --episode shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list<string>, title: string}
export def "podcasts-episodes-create create" [
  podcast_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  episode: record # PodcastEpisode model — shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list<string>, title: string}
  file_logo: string # format: binary
  file_media: string # format: binary
]: any -> record<author: string, block: bool, description: string, duration: int, episode: int, episodeType: string, explicit: bool, fileUrl: string, image: string, key: string, link: string, publishDate: string, season: int, size: int, subtitle: string, summary: string, tags: list<string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key)} | format pattern "/api/v2/podcasts/{podcast_key}/episodes/create") $auth.query)
  let req_body = {"episode": $episode, "file_logo": $file_logo, "file_media": $file_media} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file_logo" "file_media"] $dry_run)
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

# Delete podcast episode
#
# DELETE /api/v2/podcasts/{podcastKey}/episodes/{episodeKey}
# operationId: deletePodcast_1
export def "podcasts-episodes delete-by-podcast-key-episode-key" [
  podcast_key: string
  episode_key: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  if ($episode_key | is-empty) { error make --unspanned { msg: "path parameter 'episodeKey' must be non-empty" } }
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key), episode_key: (encode-path-segment $episode_key)} | format pattern "/api/v2/podcasts/{podcast_key}/episodes/{episode_key}") $auth.query)
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

# Get podcast episode
#
# GET /api/v2/podcasts/{podcastKey}/episodes/{episodeKey}
# operationId: getPodcastEpisode
export def "podcasts-episodes get" [
  podcast_key: string
  episode_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: string, block: bool, description: string, duration: int, episode: int, episodeType: string, explicit: bool, fileUrl: string, image: string, key: string, link: string, publishDate: string, season: int, size: int, subtitle: string, summary: string, tags: list<string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  if ($episode_key | is-empty) { error make --unspanned { msg: "path parameter 'episodeKey' must be non-empty" } }
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key), episode_key: (encode-path-segment $episode_key)} | format pattern "/api/v2/podcasts/{podcast_key}/episodes/{episode_key}") $auth.query)
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

# Update podcast episode
#
# PUT /api/v2/podcasts/{podcastKey}/episodes/{episodeKey}
# operationId: updatePodcastEpisode
# --episode shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list<string>, title: string}
export def "podcasts-episodes update" [
  podcast_key: string
  episode_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  episode: record # PodcastEpisode model — shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list<string>, title: string}
  --file-logo: string # format: binary
]: any -> record<author: string, block: bool, description: string, duration: int, episode: int, episodeType: string, explicit: bool, fileUrl: string, image: string, key: string, link: string, publishDate: string, season: int, size: int, subtitle: string, summary: string, tags: list<string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($podcast_key | is-empty) { error make --unspanned { msg: "path parameter 'podcastKey' must be non-empty" } }
  if ($episode_key | is-empty) { error make --unspanned { msg: "path parameter 'episodeKey' must be non-empty" } }
  let full_url = (build-url $base ({podcast_key: (encode-path-segment $podcast_key), episode_key: (encode-path-segment $episode_key)} | format pattern "/api/v2/podcasts/{podcast_key}/episodes/{episode_key}") $auth.query)
  let req_body = {"episode": $episode, "file_logo": $file_logo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file_logo"] $dry_run)
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

# Get the list of Countries that can be used to filter stations in the search stations request
#
# GET /api/v2/stations/countries
# operationId: getStationCountries
export def "stations-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<iso: string, iso3: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/countries" $auth.query)
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

# Get the list of Genres that can be used to filter stations in the search stations request
#
# GET /api/v2/stations/genres
# operationId: getStationGenres
export def "stations-genres get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/genres" $auth.query)
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

# Get the list of Languages that can be used to filter stations in the search stations request
#
# GET /api/v2/stations/languages
# operationId: getStationLanguages
export def "stations-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/languages" $auth.query)
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

# List stations
#
# GET /api/v2/stations/list
# operationId: getPartnerAggregatorStations
export def "stations-list get-partner-aggregator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # default: 1
  --hits-per-page: string # default: 10
]: nothing -> record<items: table<city: string, country: string, description: string, genre: string, key: string, language: string, logo: string, name: string, stream: string, website: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "hitsPerPage" $hits_per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/stations/list" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "hitsPerPage": $hits_per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search stations
#
# POST /api/v2/stations/search
# operationId: searchStations
# --filters shape: {country?: list<string>, genre?: list<string>, language?: list<string>}
export def "stations-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # Filters for station search — shape: {country?: list<string>, genre?: list<string>, language?: list<string>}
  --hits-per-page: int # format: int32, default: 10
  --page: int # format: int32, default: 1
  --query: string
]: any -> record<hits: table<city: string, country: string, description: string, genre: string, key: string, language: string, logo: string, name: string, stream: string, website: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/search" $auth.query)
  let req_body = {"filters": $filters, "hitsPerPage": $hits_per_page, "page": $page, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
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
